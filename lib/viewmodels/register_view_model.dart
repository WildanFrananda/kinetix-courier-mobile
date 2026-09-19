import 'package:fleet_pulse_mobile/core/core.dart';
import 'package:fleet_pulse_mobile/models/models.dart';
import 'package:fleet_pulse_mobile/repositories/session_repository.dart';
import 'package:fleet_pulse_mobile/routes/app_route.dart';
import 'package:fleet_pulse_mobile/routes/app_router_state.dart';
import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';

@injectable
class RegisterViewModel extends ChangeNotifier {
  RegisterViewModel(this._router, this._session);

  final AppRouterState _router;
  final SessionRepository _session;

  String _email = '';
  String _name = '';
  String _phone = '';
  String _password = '';
  String _vehiclePlate = '';
  int _capacityKg = 100;
  bool _submitting = false;
  String? _error;
  String? _successMessage;

  bool get submitting => _submitting;
  String? get error => _error;
  String? get successMessage => _successMessage;

  void setEmail(String v) => _email = v.trim();
  void setName(String v) => _name = v.trim();
  void setPhone(String v) => _phone = v.trim();
  void setPassword(String v) => _password = v;
  void setVehiclePlate(String v) => _vehiclePlate = v.trim();
  void setCapacityKg(String v) => _capacityKg = int.tryParse(v) ?? -1;

  Future<void> submit() async {
    if (_email.isEmpty ||
        _name.isEmpty ||
        _phone.isEmpty ||
        _password.isEmpty ||
        _vehiclePlate.isEmpty) {
      _error = 'All fields are required';
      notifyListeners();

      return;
    }

    if (!_email.contains('@')) {
      _error = 'Enter a valid email address';
      notifyListeners();

      return;
    }

    if (_capacityKg <= 0) {
      _error = 'Capacity must be a number greater than zero';
      notifyListeners();

      return;
    }

    if (_password.length < 12) {
      _error = 'Password must be at least 12 characters';
      notifyListeners();

      return;
    }

    _submitting = true;
    _error = null;
    _successMessage = null;
    notifyListeners();

    final res = await _session.register(
      email: _email,
      name: _name,
      phone: _phone,
      password: _password,
      vehiclePlate: _vehiclePlate,
      capacityKg: _capacityKg,
    );

    res.fold(
      (DriverSession _) {
        _submitting = false;
        _successMessage =
            'Registration received. An administrator will approve your account.';
        notifyListeners();
        _router.replaceAll(const PendingApprovalRoute());
      },
      (Failure f) {
        _error = f.message;
        _submitting = false;
        notifyListeners();
      },
    );
  }

  void backToLogin() {
    _router.pop();
  }
}
