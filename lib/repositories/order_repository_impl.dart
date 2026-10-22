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

  static const List<int> _jpegMagic = <int>[0xFF, 0xD8, 0xFF];
  static const String _proofUnverifiable = 'proof_unverifiable';

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
        OrderUpdatedEvent(:final Order? order) =>
          order == null || order.status == OrderStatus.cancelled ? null : order,
        OrderUnassignedEvent() => null,
      };
    }
  }

  @override
  Stream<OrderId> watchUnassigned() async* {
    await for (final ChannelEvent e in _channel.events) {
      if (_toServerEvent(e) case OrderUnassignedEvent(:final OrderId id)) {
        yield id;
      }
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

    if (!_isJpeg(bytes)) {
      return const Err<String>(
        PodPhotoFailure(
          'the camera did not return a JPEG photo; take it again',
        ),
      );
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

    final PodUpload upload;

    try {
      upload = PodUpload.fromJson(reply.response);
    } on Object catch (e) {
      AppLogger.error(
        'matching sent an upload address this app cannot read',
        error: e,
      );

      return const Err<String>(PodPhotoFailure());
    }

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
    required String podPhotoUrl,
    required String podSignature,
  }) => retry(
    () => _lifecycle(
      () => _channel.delivered(
        orderId.value,
        podPhotoUrl: podPhotoUrl,
        podSignature: podSignature,
      ),
    ),
    retryIf: _worthRetryingDelivery,
  );

  bool _worthRetryingDelivery(Failure failure) {
    return failure is NetworkFailure ||
        failure is TimeoutFailure ||
        (failure is ChannelFailure && failure.reason == _proofUnverifiable);
  }

  Future<Result<Unit>> _lifecycle(
    Future<ChannelReply> Function() action,
  ) async {
    try {
      final ChannelReply reply = await action();

      return reply.isOk
          ? const Ok<Unit>(Unit.unit)
          : new Err<Unit>(failureFromReason(reply.reason));
    } on Object {
      return const Err<Unit>(NetworkFailure());
    }
  }

  bool _isJpeg(Uint8List bytes) {
    if (bytes.length < _jpegMagic.length) {
      return false;
    }

    for (int i = 0; i < _jpegMagic.length; i++) {
      if (bytes[i] != _jpegMagic[i]) {
        return false;
      }
    }

    return true;
  }

  ServerEvent? _toServerEvent(ChannelEvent e) {
    return switch (e.event) {
      'active_order' => new ActiveOrderEvent(_orderOf(e.payload['order'])),
      'order_assigned' => _assigned(e.payload),
      'order_updated' => new OrderUpdatedEvent(_orderOf(e.payload)),
      'order_unassigned' => _unassigned(e.payload),
      _ => null,
    };
  }

  ServerEvent? _assigned(Map<String, dynamic> payload) {
    final Order? order = _orderOf(payload);

    return order == null ? null : new OrderAssignedEvent(order);
  }

  ServerEvent? _unassigned(Map<String, dynamic> payload) {
    final Object? id = payload['id'];

    return id is int ? new OrderUnassignedEvent(new OrderId(id)) : null;
  }

  Order? _orderOf(Object? raw) {
    if (raw is! Map<dynamic, dynamic>) {
      return null;
    }

    final Map<String, dynamic> json = raw.cast<String, dynamic>();

    if (json['status'] == 'pending' || json['assigned_at'] == null) {
      return null;
    }

    try {
      return Order.fromJson(json);
    } on Object catch (e) {
      AppLogger.error('dropped a job this app cannot read', error: e);

      return null;
    }
  }
}
