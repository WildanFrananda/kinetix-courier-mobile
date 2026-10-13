import 'dart:async';

import 'package:fleet_pulse_mobile/core/core.dart';
import 'package:fleet_pulse_mobile/maps/maps_launcher.dart';
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

  StreamSubscription<Order?>? _sub;
  bool _bound = false;

  Order? _order;
  bool _submitting = false;
  bool _cancelled = false;
  Failure? _error;

  OrderUiState get state {
    if (_cancelled || _order == null) {
      return const OrderCancelled();
    }

    return OrderShowing(_order!, submitting: _submitting, error: _error);
  }

  void bind(Order order) {
    if (_bound) {
      return;
    }

    _bound = true;
    _order = order;
    _sub = _orders.watchActiveOrder().listen(_onOrder);
  }

  String? _podPhotoUrl;
  String? _podSignature;
  bool _photoUploading = false;

  String? get podPhotoUrl => _podPhotoUrl;
  String? get podSignature => _podSignature;
  bool get photoUploading => _photoUploading;

  bool get canDeliver =>
      _podPhotoUrl != null && !_photoUploading && !_submitting;

  Future<void> attachPhoto(String localPath) async {
    final Order? order = _order;

    if (order == null) {
      return;
    }

    _photoUploading = true;
    _error = null;
    notifyListeners();

    final res = await _orders.attachPodPhoto(order.id, localPath);

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

    final res = await _orders.pickup(order.id);
    res.fold((_) => _error = null, (Failure f) => _error = f);
    _submitting = false;
    notifyListeners();
  }

  Future<void> delivered() async {
    final Order? order = _order;

    if (order == null || !canDeliver) {
      return;
    }

    _submitting = true;
    _error = null;
    notifyListeners();

    final res = await _orders.delivered(
      order.id,
      podPhotoUrl: _podPhotoUrl,
      podSignature: _podSignature,
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

  void _onOrder(Order? order) {
    if (_order == null) {
      _cancelled = true;
    } else {
      _order = order;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_sub?.cancel());
    super.dispose();
  }
}
