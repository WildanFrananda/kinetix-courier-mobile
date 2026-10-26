import 'package:fleet_pulse_mobile/routes/app_route.dart';
import 'package:fleet_pulse_mobile/routes/app_router_state.dart';
import 'package:fleet_pulse_mobile/viewmodels/update_required_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('trying again starts over from the splash, which asks again', () {
    final AppRouterState router = new AppRouterState()
      ..replaceAll(const UpdateRequiredRoute());

    new UpdateRequiredViewModel(router).tryAgain();

    expect(router.stack.single, isA<SplashRoute>());
  });
}
