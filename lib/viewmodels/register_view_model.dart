import 'dart:convert';

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

  static const int minPasswordLength = 12;
  static const int maxPasswordBytes = 72;
  static const int minNameLength = 2;
  static const int maxNameLength = 120;
  static const int maxPlateLength = 20;
  static const int minCapacityKg = 1;
  static const int maxCapacityKg = 5000;

  static final RegExp _phonePattern = new RegExp(r'^\+?[0-9]{8,15}$');
  static final RegExp _phoneSeparators = new RegExp(r'[\s\-.()]');

  final AppRouterState _router;
  final SessionRepository _session;

  String _email = '';
  String _name = '';
  String _phone = '';
  String _password = '';
  String _vehiclePlate = '';
  String _capacity = '';
  bool _submitting = false;
  String? _error;
  String? _successMessage;

  bool get submitting => _submitting;
  String? get error => _error;
  String? get successMessage => _successMessage;

  void setEmail(String v) => _email = v.trim();
  void setName(String v) => _name = v.trim();
  void setPhone(String v) => _phone = v.replaceAll(_phoneSeparators, '');
  void setPassword(String v) => _password = v;
  void setVehiclePlate(String v) => _vehiclePlate = v.trim();
  void setCapacityKg(String v) => _capacity = v.trim();

  Future<void> submit() async {
    final String? problem = _problem();

    if (problem != null) {
      _error = problem;
      notifyListeners();

      return;
    }

    _submitting = true;
    _error = null;
    _successMessage = null;
    notifyListeners();

    final Result<DriverSession> res = await _session.register(
      email: _email,
      name: _name,
      phone: _phone,
      password: _password,
      vehiclePlate: _vehiclePlate,
      capacityKg: int.parse(_capacity),
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

  String? _problem() {
    if (_email.isEmpty ||
        _name.isEmpty ||
        _phone.isEmpty ||
        _password.isEmpty ||
        _vehiclePlate.isEmpty ||
        _capacity.isEmpty) {
      return 'All fields are required';
    }

    if (!_email.contains('@')) {
      return 'Enter a valid email address';
    }

    if (_name.length < minNameLength || _name.length > maxNameLength) {
      return 'Enter your full name, $minNameLength to $maxNameLength '
          'characters';
    }

    if (!_phonePattern.hasMatch(_phone)) {
      return 'The phone number must be 8 to 15 digits, optionally after a +';
    }

    if (_vehiclePlate.length > maxPlateLength) {
      return 'The vehicle plate can be at most $maxPlateLength characters';
    }

    final int? capacityKg = int.tryParse(_capacity);

    if (capacityKg == null ||
        capacityKg < minCapacityKg ||
        capacityKg > maxCapacityKg) {
      return 'Capacity must be a whole number of kilograms from '
          '$minCapacityKg to $maxCapacityKg';
    }

    if (_password.length < minPasswordLength) {
      return 'Password must be at least $minPasswordLength characters';
    }

    if (utf8.encode(_password).length > maxPasswordBytes) {
      return 'Password must be at most $maxPasswordBytes bytes; accented '
          'letters and emoji take more than one';
    }

    return null;
  }
}
