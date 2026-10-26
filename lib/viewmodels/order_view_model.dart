import 'dart:async';

import 'package:fleet_pulse_mobile/core/core.dart';
import 'package:fleet_pulse_mobile/maps/maps_launcher.dart';
import 'package:fleet_pulse_mobile/models/models.dart';
import 'package:fleet_pulse_mobile/repositories/order_repository.dart';
import 'package:fleet_pulse_mobile/routes/app_router_state.dart';
import 'package:fleet_pulse_mobile/state/job_update.dart';
import 'package:fleet_pulse_mobile/state/order_ui_state.dart';
import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart' hide Order;

@injectable
class OrderViewModel extends ChangeNotifier {
  OrderViewModel(this._router, this._orders, this._maps);

  final AppRouterState _router;
  final OrderRepository _orders;
  final MapsLauncher _maps;

  StreamSubscription<JobUpdate>? _jobSub;
  bool _bound = false;
  bool _disposed = false;

  Order? _order;
  bool _submitting = false;
  OrderUiState? _ended;
  Failure? _error;

  String? _podPhotoUrl;
  String? _podSignature;
  bool _photoUploading = false;

  OrderUiState get state {
    final OrderUiState? ended = _ended;
    final Order? order = _order;

    if (ended != null) {
      return ended;
    }

    if (order == null) {
      return const OrderNoLongerActive();
    }

    return new OrderShowing(order, submitting: _submitting, error: _error);
  }

  String? get podPhotoUrl => _podPhotoUrl;
  String? get podSignature => _podSignature;
  bool get photoUploading => _photoUploading;

  bool get canDeliver =>
      _podPhotoUrl != null &&
      _podSignature != null &&
      !_photoUploading &&
      !_submitting;

  void bind(Order order) {
    if (_bound) {
      return;
    }

    _bound = true;
    _order = order;
    _jobSub = _orders.watchJobs().listen(_onJob);
    unawaited(_restoreDraft(order.id));
  }

  Future<void> attachPhoto(String localPath) async {
    final Order? order = _order;

    if (order == null) {
      return;
    }

    _photoUploading = true;
    _error = null;
    _notify();

    final Result<String> res = await _orders.attachPodPhoto(
      order.id,
      localPath,
    );

    res.fold((String photoUrl) => _podPhotoUrl = photoUrl, (Failure f) {
      _error = f;
    });
    _photoUploading = false;
    _notify();
  }

  Future<void> setPodSignature(String signatureData) async {
    final Order? order = _order;

    _podSignature = signatureData;
    _notify();

    if (order != null) {
      await _orders.keepSignature(order.id, signatureData);
    }
  }

  Future<void> pickup() async {
    final Order? order = _order;

    if (order == null) {
      return;
    }

    _submitting = true;
    _error = null;
    _notify();

    final Result<Unit> res = await _orders.pickup(order.id);

    res.fold((_) => _error = null, (Failure f) => _error = f);
    _submitting = false;
    _notify();
  }

  Future<void> delivered() async {
    final Order? order = _order;
    final String? photoUrl = _podPhotoUrl;
    final String? signature = _podSignature;

    if (order == null || photoUrl == null || signature == null || !canDeliver) {
      return;
    }

    _submitting = true;
    _error = null;
    _notify();

    final Result<Unit> res = await _orders.delivered(
      order.id,
      podPhotoUrl: photoUrl,
      podSignature: signature,
    );

    res.fold(
      (_) {
        if (!_disposed) {
          _router.pop();
        }
      },
      (Failure f) {
        _error = f;
        _submitting = false;
        _notify();
      },
    );
  }

  Future<void> navigateToPickup() async {
    final Order? o = _order;

    if (o != null) {
      await _maps.openCoordinates(o.pickup.latitude, o.pickup.longitude);
    }
  }

  Future<void> navigateToDropoff() async {
    final Order? o = _order;

    if (o != null) {
      await _maps.openCoordinates(o.dropoff.latitude, o.dropoff.longitude);
    }
  }

  void back() => _router.pop();

  Future<void> _restoreDraft(OrderId orderId) async {
    final DeliveryProofDraft draft = await _orders.proofDraft(orderId);

    if (_disposed) {
      return;
    }

    _podPhotoUrl ??= draft.photoUrl;
    _podSignature ??= draft.signature;
    _notify();
  }

  void _onJob(JobUpdate update) {
    final Order? current = _order;

    if (current == null || _ended != null) {
      return;
    }

    switch (update) {
      case JobActive(:final Order order) when order.id == current.id:
        _order = order;
      case JobCancelled(:final OrderId id) when id == current.id:
        _end(const OrderCancelled(), current.id);
      case JobUnassigned(:final OrderId id) when id == current.id:
        _end(const OrderUnassigned(), current.id);
      case JobNone():
        _end(const OrderNoLongerActive(), current.id);
      case JobActive() || JobCancelled() || JobUnassigned():
        return;
    }

    _notify();
  }

  void _end(OrderUiState ended, OrderId orderId) {
    _ended = ended;
    unawaited(_orders.discardProofDraft(orderId));
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_jobSub?.cancel());
    super.dispose();
  }
}
