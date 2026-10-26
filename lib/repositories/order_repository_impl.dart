import 'dart:typed_data';

import 'package:crypto/crypto.dart' show sha256;
import 'package:fleet_pulse_mobile/core/core.dart';
import 'package:fleet_pulse_mobile/mixins/retry_mixin.dart';
import 'package:fleet_pulse_mobile/models/models.dart';
import 'package:fleet_pulse_mobile/repositories/order_repository.dart';
import 'package:fleet_pulse_mobile/services/channel/channel_client.dart';
import 'package:fleet_pulse_mobile/services/channel/channel_event.dart';
import 'package:fleet_pulse_mobile/services/channel/channel_reply.dart';
import 'package:fleet_pulse_mobile/services/channel/push_timeout_exception.dart';
import 'package:fleet_pulse_mobile/services/storage/pod_photo_uploader.dart';
import 'package:fleet_pulse_mobile/services/storage/proof_draft_store.dart';
import 'package:fleet_pulse_mobile/state/job_update.dart';
import 'package:injectable/injectable.dart' hide Order;

@LazySingleton(as: OrderRepository)
class OrderRepositoryImpl with RetryMixin implements OrderRepository {
  OrderRepositoryImpl(this._channel, this._uploader, this._drafts);

  static const List<int> _jpegMagic = <int>[0xFF, 0xD8, 0xFF];
  static const String _proofUnverifiable = 'proof_unverifiable';

  final ChannelClient _channel;
  final PodPhotoUploader _uploader;
  final ProofDraftStore _drafts;

  @override
  Stream<JobUpdate> watchJobs() async* {
    await for (final ChannelEvent e in _channel.events) {
      final JobUpdate? update = _toJobUpdate(e);

      if (update != null) {
        yield update;
      }
    }
  }

  @override
  Future<Result<Unit>> pickup(OrderId orderId) => retry(
    () => _lifecycle(() => _channel.pickup(orderId.value)),
    maxAttempts: null,
    stillWanted: _sessionHeld,
  );

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

    await _keepDraft(
      (DriverId driver) => _drafts.keepPhoto(driver, orderId, upload.photoUrl),
    );

    return new Ok<String>(upload.photoUrl);
  }

  @override
  Future<DeliveryProofDraft> proofDraft(OrderId orderId) async {
    final DriverId? driver = _channel.driverId;

    if (driver == null) {
      return const DeliveryProofDraft();
    }

    try {
      return await _drafts.read(driver, orderId);
    } on Object catch (e) {
      AppLogger.error('the kept proof of delivery could not be read', error: e);

      return const DeliveryProofDraft();
    }
  }

  @override
  Future<void> keepSignature(OrderId orderId, String podSignature) {
    return _keepDraft(
      (DriverId driver) => _drafts.keepSignature(driver, orderId, podSignature),
    );
  }

  @override
  Future<void> discardProofDraft(OrderId orderId) {
    return _keepDraft((DriverId driver) => _drafts.forget(driver, orderId));
  }

  @override
  Future<Result<Unit>> delivered(
    OrderId orderId, {
    required String podPhotoUrl,
    required String podSignature,
  }) async {
    final Result<Unit> delivered = await retry(
      () => _lifecycle(
        () => _channel.delivered(
          orderId.value,
          podPhotoUrl: podPhotoUrl,
          podSignature: podSignature,
        ),
      ),
      maxAttempts: null,
      retryIf: _worthRetryingDelivery,
      stillWanted: _sessionHeld,
    );

    if (delivered is Ok<Unit>) {
      await discardProofDraft(orderId);
    }

    return delivered;
  }

  bool _sessionHeld() => _channel.driverId != null;

  Future<void> _keepDraft(Future<void> Function(DriverId driver) change) async {
    final DriverId? driver = _channel.driverId;

    if (driver == null) {
      return;
    }

    try {
      await change(driver);
    } on Object catch (e) {
      AppLogger.error('the proof of delivery could not be kept', error: e);
    }
  }

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
    } on PushTimeoutException {
      return const Err<Unit>(TimeoutFailure());
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

  JobUpdate? _toJobUpdate(ChannelEvent e) {
    return switch (e.event) {
      'active_order' => _activeOrder(e.payload['order']),
      'order_assigned' => _assigned(e.payload),
      'order_updated' => _updated(e.payload),
      'order_unassigned' => _unassigned(e.payload),
      _ => null,
    };
  }

  JobUpdate? _activeOrder(Object? raw) {
    if (raw == null) {
      return const JobNone();
    }

    final Order? order = _orderOf(raw);

    return order == null ? null : new JobActive(order);
  }

  JobUpdate? _assigned(Map<String, dynamic> payload) {
    final Order? order = _orderOf(payload);

    return order == null ? null : new JobActive(order);
  }

  JobUpdate? _updated(Map<String, dynamic> payload) {
    final Object? id = payload['id'];

    if (id is int &&
        (payload['status'] == 'pending' || payload['assigned_at'] == null)) {
      return new JobUnassigned(new OrderId(id));
    }

    final Order? order = _orderOf(payload);

    if (order == null) {
      return null;
    }

    return order.status == OrderStatus.cancelled
        ? new JobCancelled(order.id)
        : new JobActive(order);
  }

  JobUpdate? _unassigned(Map<String, dynamic> payload) {
    final Object? id = payload['id'];

    return id is int ? new JobUnassigned(new OrderId(id)) : null;
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
