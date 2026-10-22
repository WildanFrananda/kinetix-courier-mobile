import 'package:fleet_pulse_mobile/di/injection.dart';
import 'package:fleet_pulse_mobile/repositories/connection_repository.dart';
import 'package:fleet_pulse_mobile/repositories/duty_repository.dart';
import 'package:fleet_pulse_mobile/repositories/order_repository.dart';
import 'package:fleet_pulse_mobile/repositories/session_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(getIt.reset);

  test(
    'the generated container builds every repository and disposes them',
    () async {
      await configureDependencies();

      expect(getIt<SessionRepository>(), isNotNull);
      expect(getIt<ConnectionRepository>(), isNotNull);
      expect(getIt<DutyRepository>(), isNotNull);
      expect(getIt<OrderRepository>(), isNotNull);
    },
  );
}
