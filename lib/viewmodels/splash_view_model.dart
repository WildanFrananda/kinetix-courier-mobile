import 'dart:async';

import 'package:fleet_pulse_mobile/core/core.dart';
import 'package:fleet_pulse_mobile/models/models.dart';
import 'package:fleet_pulse_mobile/repositories/session_repository.dart';
import 'package:fleet_pulse_mobile/routes/app_route.dart';
import 'package:fleet_pulse_mobile/routes/app_router_state.dart';
import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';

@injectable
class SplashViewModel extends ChangeNotifier {
  SplashViewModel(this._router, this._session) {
    unawaited(_bootstrap());
  }

  final AppRouterState _router;
  final SessionRepository _session;

  Future<void> _bootstrap() async {
    final DriverSession? session = await _session.currentSession();

    await Future<void>.delayed(const Duration(milliseconds: 400));

    if (session == null) {
      _router.replaceAll(const LoginRoute());

      return;
    }

    switch (await _session.standing()) {
      case Ok<DriverProfile>():
        _router.replaceAll(const TrackingRoute());
      case Err<DriverProfile>(:final Failure failure)
          when failure is PendingApprovalFailure:
        _router.replaceAll(const PendingApprovalRoute());
      case Err<DriverProfile>(:final Failure failure)
          when failure is AppUpdateRequiredFailure:
        _router.replaceAll(const UpdateRequiredRoute());
      case Err<DriverProfile>(:final Failure failure)
          when failure is AuthFailure ||
              failure is RegistrationIncompleteFailure:
        await _session.logout();
        _router.replaceAll(const LoginRoute());
      case Err<DriverProfile>():
        _router.replaceAll(const TrackingRoute());
    }
  }
}
