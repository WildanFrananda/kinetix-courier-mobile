import 'package:flutter_test/flutter_test.dart';
import 'package:kinetix_courier/routes/app_route.dart';
import 'package:kinetix_courier/routes/app_router_state.dart';
import 'package:kinetix_courier/viewmodels/update_required_view_model.dart';

void main() {
  test('trying again starts over from the splash, which asks again', () {
    final AppRouterState router = new AppRouterState()
      ..replaceAll(const UpdateRequiredRoute());

    new UpdateRequiredViewModel(router).tryAgain();

    expect(router.stack.single, isA<SplashRoute>());
  });
}
