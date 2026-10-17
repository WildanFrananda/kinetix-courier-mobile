import 'dart:typed_data';

import 'package:crypto/crypto.dart' show sha256;
import 'package:fleet_pulse_mobile/core/core.dart';
import 'package:fleet_pulse_mobile/mixins/retry_mixin.dart';
import 'package:fleet_pulse_mobile/models/models.dart';
import 'package:fleet_pulse_mobile/repositories/order_repository.dart';
import 'package:fleet_pulse_mobile/services/channel/channel_client.dart';
import 'package:fleet_pulse_mobile/services/channel/channel_event.dart';
import 'package:fleet_pulse_mobile/services/storage/pod_photo_uploader.dart';
import 'package:fleet_pulse_mobile/state/state.dart';
import 'package:injectable/injectable.dart' hide Order;

@LazySingleton(as: OrderRepository)
class OrderRepositoryImpl with RetryMixin implements OrderRepository {
  OrderRepositoryImpl(this._channel, this._uploader);

  final ChannelClient _channel;
  final PodPhotoUploader _uploader;

  @override
  Stream<Order?> watchActiveOrder() async* {
    await for (final ChannelEvent e in _channel.events) {
      final ServerEvent? event = _toServerEvent(e);

      if (event == null) {
        continue;
      }

      yield switch (event) {
        ActiveOrderEvent(:final Order? order) => order,
        OrderAssignedEvent(:final Order order) => order,
        OrderUpdatedEvent(:final Order order) =>
          order.status == OrderStatus.cancelled ? null : order,
      };
    }
  }

  @override
  Future<Result<Unit>> pickup(OrderId orderId) =>
      retry(() => _lifecycle(() => _channel.pickup(orderId.value)));

  @override
  Future<Result<String>> attachPodPhoto(
    OrderId orderId,
    String localPath,
  ) async {
    final Uint8List bytes;

    try {
      bytes = await _uploader.read(localPath);
    } on Object {
      return const Err<String>(PodPhotoFailure());
    }

    final String photoSha256 = sha256.convert(bytes).toString();
    final ChannelReply reply;

    try {
      reply = await _channel.podUpload(orderId.value, photoSha256);
    } on Object {
      return const Err<String>(NetworkFailure());
    }

    if (!reply.isOk) {
      return new Err<String>(failureFromReason(reply.reason));
    }

    final PodUpload upload = PodUpload.fromJson(reply.response);

    try {
      await _uploader.upload(upload.uploadUrl, bytes, upload.uploadHeaders);
    } on Object {
      return const Err<String>(PodPhotoFailure());
    }

    return new Ok<String>(upload.photoUrl);
  }

  @override
  Future<Result<Unit>> delivered(
    OrderId orderId, {
    String? podPhotoUrl,
    String? podSignature,
  }) => retry(
    () => _lifecycle(
      () => _channel.delivered(
        orderId.value,
        podPhotoUrl: podPhotoUrl,
        podSignature: podSignature,
      ),
    ),
  );

  Future<Result<Unit>> _lifecycle(
    Future<ChannelReply> Function() action,
  ) async {
    try {
      final ChannelReply reply = await action();

      return reply.isOk
          ? const Ok<Unit>(Unit.unit)
          : new Err<Unit>(failureFromReason(reply.reason));
    } on ChannelException {
      return const Err<Unit>(NetworkFailure());
    } on Object {
      return const Err<Unit>(NetworkFailure());
    }
  }

  ServerEvent? _toServerEvent(ChannelEvent e) {
    Map<String, dynamic> asOrder(Object? raw) =>
        (raw as Map<dynamic, dynamic>).cast<String, dynamic>();

    return switch (e.event) {
      'active_order' => new ActiveOrderEvent(
        e.payload['order'] == null
            ? null
            : Order.fromJson(asOrder(e.payload['order'])),
      ),
      'order_assigned' => new OrderAssignedEvent(
        Order.fromJson(asOrder(e.payload)),
      ),
      'order_updated' => new OrderUpdatedEvent(
        Order.fromJson(asOrder(e.payload)),
      ),
      _ => null,
    };
  }
}
