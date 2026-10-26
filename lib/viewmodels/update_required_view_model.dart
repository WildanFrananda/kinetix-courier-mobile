import 'package:fleet_pulse_mobile/routes/app_route.dart';
import 'package:fleet_pulse_mobile/routes/app_router_state.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

@injectable
class UpdateRequiredViewModel extends ChangeNotifier {
  UpdateRequiredViewModel(this._router);

  final AppRouterState _router;

  void tryAgain() => _router.replaceAll(const SplashRoute());
}
