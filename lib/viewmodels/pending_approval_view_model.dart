import 'package:fleet_pulse_mobile/repositories/session_repository.dart';
import 'package:fleet_pulse_mobile/routes/app_route.dart';
import 'package:fleet_pulse_mobile/routes/app_router_state.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

@injectable
class PendingApprovalViewModel extends ChangeNotifier {
  PendingApprovalViewModel(this._router, this._session);

  final AppRouterState _router;
  final SessionRepository _session;

  Future<void> backToLogin() async {
    await _session.logout();
    _router.replaceAll(const LoginRoute());
  }
}
