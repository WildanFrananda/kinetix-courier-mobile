import 'package:flutter_test/flutter_test.dart';
import 'package:kinetix_courier/di/injection.dart';
import 'package:kinetix_courier/repositories/connection_repository.dart';
import 'package:kinetix_courier/repositories/duty_repository.dart';
import 'package:kinetix_courier/repositories/order_repository.dart';
import 'package:kinetix_courier/repositories/session_repository.dart';

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
