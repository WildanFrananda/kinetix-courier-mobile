import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:kinetix_courier/routes/app_route.dart';
import 'package:kinetix_courier/routes/app_router_state.dart';

@injectable
class UpdateRequiredViewModel extends ChangeNotifier {
  UpdateRequiredViewModel(this._router);

  final AppRouterState _router;

  void tryAgain() => _router.replaceAll(const SplashRoute());
}
