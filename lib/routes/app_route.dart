import 'package:fleet_pulse_mobile/models/order.dart';

sealed class AppRoute {
  const AppRoute();
}

class SplashRoute extends AppRoute {
  const SplashRoute();
}

class LoginRoute extends AppRoute {
  const LoginRoute();
}

class RegisterRoute extends AppRoute {
  const RegisterRoute();
}

class PendingApprovalRoute extends AppRoute {
  const PendingApprovalRoute();
}

class UpdateRequiredRoute extends AppRoute {
  const UpdateRequiredRoute();
}

class TrackingRoute extends AppRoute {
  const TrackingRoute();
}

class OrderRoute extends AppRoute {
  const OrderRoute({required this.order});

  final Order order;
}
