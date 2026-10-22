import 'package:fleet_pulse_mobile/repositories/session_repository.dart';
import 'package:fleet_pulse_mobile/routes/app_route.dart';
import 'package:fleet_pulse_mobile/routes/app_router_state.dart';
import 'package:fleet_pulse_mobile/viewmodels/pending_approval_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSession extends Mock implements SessionRepository {}

void main() {
  test(
    'backToLogin signs out, then replaces the stack with LoginRoute',
    () async {
      final _MockSession session = new _MockSession();
      when(session.logout).thenAnswer((_) async {});
      final AppRouterState router = new AppRouterState()
        ..push(const PendingApprovalRoute());

      await new PendingApprovalViewModel(router, session).backToLogin();

      verify(session.logout).called(1);
      expect(router.stack.last, isA<LoginRoute>());
      expect(router.stack.length, 1);
    },
  );
}
