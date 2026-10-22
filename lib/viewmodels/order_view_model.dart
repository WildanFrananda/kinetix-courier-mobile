import 'dart:async';

import 'package:fleet_pulse_mobile/core/core.dart';
import 'package:fleet_pulse_mobile/maps/maps_launcher.dart';
import 'package:fleet_pulse_mobile/models/ids.dart';
import 'package:fleet_pulse_mobile/models/order.dart';
import 'package:fleet_pulse_mobile/repositories/order_repository.dart';
import 'package:fleet_pulse_mobile/routes/app_router_state.dart';
import 'package:fleet_pulse_mobile/state/order_ui_state.dart';
import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart' hide Order;

@injectable
class OrderViewModel extends ChangeNotifier {
  OrderViewModel(this._router, this._orders, this._maps);

  final AppRouterState _router;
  final OrderRepository _orders;
  final MapsLauncher _maps;

  StreamSubscription<Order?>? _orderSub;
  StreamSubscription<OrderId>? _unassignedSub;
  bool _bound = false;

  Order? _order;
  bool _submitting = false;
  bool _cancelled = false;
  bool _unassigned = false;
  Failure? _error;

  String? _podPhotoUrl;
  String? _podSignature;
  bool _photoUploading = false;

  OrderUiState get state {
    final Order? order = _order;

    if (_unassigned) {
      return const OrderUnassigned();
    }

    if (_cancelled || order == null) {
      return const OrderCancelled();
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
    _orderSub = _orders.watchActiveOrder().listen(_onOrder);
    _unassignedSub = _orders.watchUnassigned().listen(_onUnassigned);
  }

  Future<void> attachPhoto(String localPath) async {
    final Order? order = _order;

    if (order == null) {
      return;
    }

    _photoUploading = true;
    _error = null;
    notifyListeners();

    final Result<String> res = await _orders.attachPodPhoto(
      order.id,
      localPath,
    );

    res.fold((String photoUrl) => _podPhotoUrl = photoUrl, (Failure f) {
      _error = f;
    });
    _photoUploading = false;
    notifyListeners();
  }

  void setPodSignature(String signatureData) {
    _podSignature = signatureData;
    notifyListeners();
  }

  Future<void> pickup() async {
    final Order? order = _order;

    if (order == null) {
      return;
    }

    _submitting = true;
    _error = null;
    notifyListeners();

    final Result<Unit> res = await _orders.pickup(order.id);

    res.fold((_) => _error = null, (Failure f) => _error = f);
    _submitting = false;
    notifyListeners();
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
    notifyListeners();

    final Result<Unit> res = await _orders.delivered(
      order.id,
      podPhotoUrl: photoUrl,
      podSignature: signature,
    );

    res.fold((_) => _router.pop(), (Failure f) {
      _error = f;
      _submitting = false;
      notifyListeners();
    });
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

  void _onOrder(Order? incoming) {
    final Order? current = _order;

    if (current == null) {
      return;
    }

    if (incoming == null || incoming.id != current.id) {
      _cancelled = true;
    } else {
      _order = incoming;
    }

    notifyListeners();
  }

  void _onUnassigned(OrderId id) {
    if (_order?.id != id) {
      return;
    }

    _unassigned = true;
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_orderSub?.cancel());
    unawaited(_unassignedSub?.cancel());
    super.dispose();
  }
}
