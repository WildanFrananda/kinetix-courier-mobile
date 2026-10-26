import 'package:fleet_pulse_mobile/di/injection.dart';
import 'package:fleet_pulse_mobile/models/order.dart';
import 'package:fleet_pulse_mobile/routes/app_route.dart';
import 'package:fleet_pulse_mobile/ui/screens/login_screen.dart';
import 'package:fleet_pulse_mobile/ui/screens/order_screen.dart';
import 'package:fleet_pulse_mobile/ui/screens/pending_approval_screen.dart';
import 'package:fleet_pulse_mobile/ui/screens/register_screen.dart';
import 'package:fleet_pulse_mobile/ui/screens/splash_screen.dart';
import 'package:fleet_pulse_mobile/ui/screens/tracking_screen.dart';
import 'package:fleet_pulse_mobile/ui/screens/update_required_screen.dart';
import 'package:fleet_pulse_mobile/viewmodels/login_view_model.dart';
import 'package:fleet_pulse_mobile/viewmodels/order_view_model.dart';
import 'package:fleet_pulse_mobile/viewmodels/pending_approval_view_model.dart';
import 'package:fleet_pulse_mobile/viewmodels/register_view_model.dart';
import 'package:fleet_pulse_mobile/viewmodels/splash_view_model.dart';
import 'package:fleet_pulse_mobile/viewmodels/tracking_view_model.dart';
import 'package:fleet_pulse_mobile/viewmodels/update_required_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AppRouteMapper {
  const AppRouteMapper();

  Page<dynamic> toPage(AppRoute route) {
    return switch (route) {
      SplashRoute() => MaterialPage<void>(
        key: const ValueKey<String>('splash'),
        child: _inject<SplashViewModel>(const SplashScreen()),
      ),
      LoginRoute() => MaterialPage<void>(
        key: const ValueKey<String>('login'),
        child: _inject<LoginViewModel>(const LoginScreen()),
      ),
      RegisterRoute() => MaterialPage<void>(
        key: const ValueKey<String>('register'),
        child: _inject<RegisterViewModel>(const RegisterScreen()),
      ),
      PendingApprovalRoute() => MaterialPage<void>(
        key: const ValueKey<String>('pending-approval'),
        child: _inject<PendingApprovalViewModel>(const PendingApprovalScreen()),
      ),
      UpdateRequiredRoute() => MaterialPage<void>(
        key: const ValueKey<String>('update-required'),
        child: _inject<UpdateRequiredViewModel>(const UpdateRequiredScreen()),
      ),
      TrackingRoute() => MaterialPage<void>(
        key: const ValueKey<String>('tracking'),
        child: _inject<TrackingViewModel>(const TrackingScreen()),
      ),
      OrderRoute(:final Order order) => MaterialPage<void>(
        key: ValueKey<String>('order-${order.id}'),
        child: _inject<OrderViewModel>(OrderScreen(order: order)),
      ),
    };
  }

  Widget _inject<T extends ChangeNotifier>(Widget child) {
    return ChangeNotifierProvider<T>(create: (_) => getIt<T>(), child: child);
  }
}
