import 'package:flutter/material.dart';
import 'package:kinetix_courier/di/injection.dart';
import 'package:kinetix_courier/models/order.dart';
import 'package:kinetix_courier/routes/app_route.dart';
import 'package:kinetix_courier/ui/screens/credential_screen.dart';
import 'package:kinetix_courier/ui/screens/login_screen.dart';
import 'package:kinetix_courier/ui/screens/order_screen.dart';
import 'package:kinetix_courier/ui/screens/pending_approval_screen.dart';
import 'package:kinetix_courier/ui/screens/present_screen.dart';
import 'package:kinetix_courier/ui/screens/register_screen.dart';
import 'package:kinetix_courier/ui/screens/splash_screen.dart';
import 'package:kinetix_courier/ui/screens/tracking_screen.dart';
import 'package:kinetix_courier/ui/screens/update_required_screen.dart';
import 'package:kinetix_courier/viewmodels/credential_view_model.dart';
import 'package:kinetix_courier/viewmodels/login_view_model.dart';
import 'package:kinetix_courier/viewmodels/order_view_model.dart';
import 'package:kinetix_courier/viewmodels/pending_approval_view_model.dart';
import 'package:kinetix_courier/viewmodels/present_view_model.dart';
import 'package:kinetix_courier/viewmodels/register_view_model.dart';
import 'package:kinetix_courier/viewmodels/splash_view_model.dart';
import 'package:kinetix_courier/viewmodels/tracking_view_model.dart';
import 'package:kinetix_courier/viewmodels/update_required_view_model.dart';
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
      CredentialRoute() => MaterialPage<void>(
        key: const ValueKey<String>('credential'),
        child: _inject<CredentialViewModel>(const CredentialScreen()),
      ),
      PresentRoute() => MaterialPage<void>(
        key: const ValueKey<String>('present'),
        child: _inject<PresentViewModel>(const PresentScreen()),
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
