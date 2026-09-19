import 'package:fleet_pulse_mobile/core/core.dart';
import 'package:fleet_pulse_mobile/repositories/session_repository.dart';
import 'package:fleet_pulse_mobile/routes/app_route.dart';
import 'package:fleet_pulse_mobile/routes/app_router_state.dart';
import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';

@injectable
class LoginViewModel extends ChangeNotifier {
  LoginViewModel(this._router, this._session);

  final AppRouterState _router;
  final SessionRepository _session;

  String _email = '';
  String _password = '';
  bool _submitting = false;
  String? _error;

  bool get submitting => _submitting;
  String? get error => _error;

  void setEmail(String v) => _email = v.trim();
  void setPassword(String v) => _password = v;

  Future<void> submit() async {
    if (_email.isEmpty || _password.isEmpty) {
      _error = 'email and password required';
      notifyListeners();

      return;
    }

    _submitting = true;
    _error = null;
    notifyListeners();

    final res = await _session.login(email: _email, password: _password);

    res.fold((_) => _router.replaceAll(const TrackingRoute()), (Failure f) {
      _submitting = false;

      if (f is PendingApprovalFailure) {
        _router.push(const PendingApprovalRoute());

        return;
      }

      if (f is RegistrationIncompleteFailure) {
        _error =
            'Your account has no vehicle yet. Finish registering to continue.';
        notifyListeners();
        _router.push(const RegisterRoute());

        return;
      }

      _error = f.message;
      notifyListeners();
    });
  }

  void navigateToRegister() => _router.push(const RegisterRoute());
}
