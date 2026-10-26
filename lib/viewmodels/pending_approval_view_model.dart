import 'package:fleet_pulse_mobile/core/core.dart';
import 'package:fleet_pulse_mobile/models/models.dart';
import 'package:fleet_pulse_mobile/repositories/session_repository.dart';
import 'package:fleet_pulse_mobile/routes/app_route.dart';
import 'package:fleet_pulse_mobile/routes/app_router_state.dart';
import 'package:fleet_pulse_mobile/state/approval_check_state.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

@injectable
class PendingApprovalViewModel extends ChangeNotifier {
  PendingApprovalViewModel(this._router, this._session);

  final AppRouterState _router;
  final SessionRepository _session;

  ApprovalCheckState _state = const ApprovalWaiting();

  ApprovalCheckState get state => _state;

  Future<void> checkAgain() async {
    if (_state is ApprovalChecking) {
      return;
    }

    _state = const ApprovalChecking();
    notifyListeners();

    final Result<DriverProfile> standing = await _session.standing();

    switch (standing) {
      case Ok<DriverProfile>():
        _router.replaceAll(const TrackingRoute());
      case Err<DriverProfile>(:final Failure failure)
          when failure is PendingApprovalFailure:
        _show(const ApprovalStillPending());
      case Err<DriverProfile>(:final Failure failure)
          when failure is AppUpdateRequiredFailure:
        _router.replaceAll(const UpdateRequiredRoute());
      case Err<DriverProfile>(:final Failure failure)
          when failure is AuthFailure ||
              failure is RegistrationIncompleteFailure:
        await backToLogin();
      case Err<DriverProfile>(:final Failure failure):
        _show(new ApprovalCheckFailed(failure.message));
    }
  }

  Future<void> backToLogin() async {
    await _session.logout();
    _router.replaceAll(const LoginRoute());
  }

  void _show(ApprovalCheckState state) {
    _state = state;
    notifyListeners();
  }
}
