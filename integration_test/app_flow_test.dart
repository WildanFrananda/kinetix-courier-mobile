import 'dart:async';

import 'package:fleet_pulse_mobile/core/core.dart';
import 'package:fleet_pulse_mobile/di/injection.dart';
import 'package:fleet_pulse_mobile/models/models.dart';
import 'package:fleet_pulse_mobile/repositories/connection_repository.dart';
import 'package:fleet_pulse_mobile/repositories/duty_repository.dart';
import 'package:fleet_pulse_mobile/repositories/order_repository.dart';
import 'package:fleet_pulse_mobile/repositories/session_repository.dart';
import 'package:fleet_pulse_mobile/state/state.dart';
import 'package:fleet_pulse_mobile/ui/app.dart';
import 'package:fleet_pulse_mobile/ui/screens/order_screen.dart';
import 'package:fleet_pulse_mobile/viewmodels/order_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:signature/signature.dart';

const DriverSession _session = DriverSession(
  driverId: DriverId(1),
  token: 'access',
  refreshToken: 'refresh',
);

const DriverProfile _approved = DriverProfile(
  id: DriverId(1),
  vehiclePlate: 'B 1234 KIN',
  capacityKg: 150,
  status: 'offline',
  active: true,
);

const String _code = '123456';

class FakeSession implements SessionRepository {
  DriverSession? stored;
  bool pendingApproval = false;
  bool secondFactor = false;
  final List<Failure> loginRefusals = <Failure>[];
  int codesTried = 0;

  @override
  Future<DriverSession?> currentSession() async => stored;

  @override
  Future<Result<DriverProfile>> standing() async => pendingApproval
      ? const Err<DriverProfile>(PendingApprovalFailure())
      : const Ok<DriverProfile>(_approved);

  @override
  Future<Result<LoginOutcome>> login({
    required String email,
    required String password,
  }) async {
    if (loginRefusals.isNotEmpty) {
      return new Err<LoginOutcome>(loginRefusals.removeAt(0));
    }

    if (pendingApproval) {
      stored = _session;

      return const Err<LoginOutcome>(PendingApprovalFailure());
    }

    if (secondFactor) {
      return const Ok<LoginOutcome>(
        SecondFactorRequired(
          TwoFactorChallenge(challengeToken: 'challenge', expiresIn: 300),
        ),
      );
    }

    stored = _session;

    return const Ok<LoginOutcome>(LoggedIn(_session));
  }

  @override
  Future<Result<DriverSession>> verifySecondFactor({
    required TwoFactorChallenge challenge,
    required String code,
  }) async {
    codesTried++;

    if (codesTried > 5) {
      return const Err<DriverSession>(
        ChallengeSpentFailure('Too many wrong codes for this sign-in.'),
      );
    }

    if (code != _code) {
      return const Err<DriverSession>(RefusedFailure('That code is not valid'));
    }

    stored = _session;

    return const Ok<DriverSession>(_session);
  }

  @override
  Future<Result<DriverSession>> register({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String vehiclePlate,
    required int capacityKg,
  }) async {
    stored = _session;
    pendingApproval = true;

    return const Ok<DriverSession>(_session);
  }

  @override
  Future<void> logout() async => stored = null;
}

class FakeConnection implements ConnectionRepository {
  final StreamController<ConnectionStatus> _status =
      new StreamController<ConnectionStatus>.broadcast();
  final StreamController<SessionEnd> _ended =
      new StreamController<SessionEnd>.broadcast();

  void end(SessionEnd end) => _ended.add(end);

  @override
  Stream<ConnectionStatus> get statusStream => _status.stream;

  @override
  Stream<SessionEnd> get sessionEnded => _ended.stream;

  @override
  Future<void> connect(DriverSession session) async =>
      _status.add(ConnectionStatus.connected);

  @override
  Future<void> disconnect() async => _status.add(ConnectionStatus.disconnected);

  @override
  void onResume() {}

  @override
  Future<void> dispose() async {
    await _status.close();
    await _ended.close();
  }
}

class FakeOrders implements OrderRepository {
  final StreamController<JobUpdate> _jobs =
      new StreamController<JobUpdate>.broadcast();

  String? deliveredWithPhoto;
  String? deliveredWithSignature;
  String? keptSignature;

  void assign(Order order) => _jobs.add(new JobActive(order));

  void takeOff(OrderId id) {
    _jobs
      ..add(new JobUnassigned(id))
      ..add(const JobNone());
  }

  @override
  Stream<JobUpdate> watchJobs() => _jobs.stream;

  @override
  Future<Result<Unit>> pickup(OrderId orderId) async {
    _jobs.add(new JobActive(_order(OrderStatus.pickedUp)));

    return const Ok<Unit>(Unit.unit);
  }

  @override
  Future<DeliveryProofDraft> proofDraft(OrderId orderId) async =>
      const DeliveryProofDraft();

  @override
  Future<void> keepSignature(OrderId orderId, String podSignature) async {
    keptSignature = podSignature;
  }

  @override
  Future<void> discardProofDraft(OrderId orderId) async {}

  @override
  Future<Result<String>> attachPodPhoto(
    OrderId orderId,
    String localPath,
  ) async => new Ok<String>(
    'https://storage.kinetix.test/kinetix-pod/pod/${orderId.value}/photo.jpg',
  );

  @override
  Future<Result<Unit>> delivered(
    OrderId orderId, {
    required String podPhotoUrl,
    required String podSignature,
  }) async {
    deliveredWithPhoto = podPhotoUrl;
    deliveredWithSignature = podSignature;

    return const Ok<Unit>(Unit.unit);
  }

  Future<void> dispose() async {
    await _jobs.close();
  }
}

class FakeDuty implements DutyRepository {
  final StreamController<DriverAvailability> _availability =
      new StreamController<DriverAvailability>.broadcast();
  final StreamController<TelemetryPing> _sent =
      new StreamController<TelemetryPing>.broadcast();
  final StreamController<Failure> _problems =
      new StreamController<Failure>.broadcast();

  bool _onDuty = false;

  @override
  bool get onDuty => _onDuty;

  @override
  Stream<DriverAvailability> get availability => _availability.stream;

  @override
  Stream<TelemetryPing> get sent => _sent.stream;

  @override
  Stream<Failure> get problems => _problems.stream;

  @override
  Future<Result<DriverAvailability>> goOnDuty() async {
    _onDuty = true;

    return const Ok<DriverAvailability>(DriverAvailability.online);
  }

  @override
  Future<Result<DriverAvailability>> goOffDuty() async {
    _onDuty = false;

    return const Ok<DriverAvailability>(DriverAvailability.offline);
  }

  @override
  Future<void> openAppSettings() async {}

  @override
  Future<void> dispose() async {
    await _availability.close();
    await _sent.close();
    await _problems.close();
  }
}

Order _order(OrderStatus status) => new Order(
  id: const OrderId(5),
  status: status,
  weightKg: 1,
  pickup: const LatLng(latitude: 1, longitude: 2),
  dropoff: const LatLng(latitude: 3, longitude: 4),
  assignedAt: DateTime.utc(2026),
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late FakeSession session;
  late FakeConnection connection;
  late FakeOrders orders;
  late FakeDuty duty;

  setUp(() async {
    await configureDependencies();
    getIt.allowReassignment = true;
    session = new FakeSession();
    connection = new FakeConnection();
    orders = new FakeOrders();
    duty = new FakeDuty();
    getIt
      ..registerLazySingleton<SessionRepository>(() => session)
      ..registerLazySingleton<ConnectionRepository>(() => connection)
      ..registerLazySingleton<OrderRepository>(() => orders)
      ..registerLazySingleton<DutyRepository>(() => duty);
  });

  tearDown(() async {
    await getIt.reset();
    await connection.dispose();
    await orders.dispose();
    await duty.dispose();
  });

  Future<void> start(WidgetTester tester) async {
    await tester.pumpWidget(const FleetPulseApp());
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
  }

  Future<void> signIn(WidgetTester tester) async {
    await tester.enterText(find.byType(TextField).at(0), 'driver@kinetix.test');
    await tester.enterText(find.byType(TextField).at(1), 'fixture-password');
    await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'login, go on duty, pick up, prove the delivery with photo and signature',
    (WidgetTester tester) async {
      await start(tester);
      expect(find.text('Log in'), findsOneWidget);

      await signIn(tester);
      expect(find.text('On duty'), findsOneWidget);

      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      expect(find.text('Availability: online'), findsOneWidget);

      orders.assign(_order(OrderStatus.assigned));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mark as Picked Up'));
      await tester.pumpAndSettle();
      expect(find.text('Status: pickedUp'), findsOneWidget);

      final Finder deliver = find.widgetWithText(
        ElevatedButton,
        'Mark as Delivered',
      );
      expect(tester.widget<ElevatedButton>(deliver).onPressed, isNull);

      final OrderViewModel vm = Provider.of<OrderViewModel>(
        tester.element(find.byType(OrderScreen)),
        listen: false,
      );
      await vm.attachPhoto('/camera/photo.jpg');
      await tester.pumpAndSettle();
      expect(tester.widget<ElevatedButton>(deliver).onPressed, isNull);

      await tester.tap(find.text('Add Signature'));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(Signature), const Offset(120, 40));
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Signed'), findsOneWidget);
      expect(orders.keptSignature, startsWith('data:image/png;base64,'));

      await tester.tap(deliver);
      await tester.pumpAndSettle();

      expect(
        orders.deliveredWithPhoto,
        'https://storage.kinetix.test/kinetix-pod/pod/5/photo.jpg',
      );
      expect(
        orders.deliveredWithSignature,
        startsWith('data:image/png;base64,'),
      );
      expect(find.text('On duty'), findsOneWidget);
    },
  );

  testWidgets('a second factor is asked for, then signs in', (
    WidgetTester tester,
  ) async {
    session.secondFactor = true;
    await start(tester);

    await signIn(tester);
    expect(find.text('Authentication code'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '000000');
    await tester.tap(find.widgetWithText(FilledButton, 'Verify'));
    await tester.pumpAndSettle();
    expect(find.text('That code is not valid'), findsOneWidget);

    await tester.enterText(find.byType(TextField), _code);
    await tester.tap(find.widgetWithText(FilledButton, 'Verify'));
    await tester.pumpAndSettle();
    expect(find.text('On duty'), findsOneWidget);
  });

  testWidgets('five wrong codes send the courier back to the password', (
    WidgetTester tester,
  ) async {
    session.secondFactor = true;
    await start(tester);
    await signIn(tester);

    for (int attempt = 0; attempt < 6; attempt++) {
      await tester.enterText(find.byType(TextField), '000000');
      await tester.tap(find.widgetWithText(FilledButton, 'Verify'));
      await tester.pumpAndSettle();
    }

    expect(find.text('Too many wrong codes for this sign-in.'), findsOneWidget);
    expect(find.text('Authentication code'), findsNothing);
    expect(find.widgetWithText(FilledButton, 'Log in'), findsOneWidget);
  });

  testWidgets(
    'a delayed sign-in says how long to wait, holds the button, then lets the courier in',
    (WidgetTester tester) async {
      session.loginRefusals.add(
        const SignInDelayedFailure(Duration(seconds: 1)),
      );
      await start(tester);

      await signIn(tester);

      expect(
        find.text('Too many sign-in attempts. Try again in 1 second.'),
        findsOneWidget,
      );
      final Finder logIn = find.widgetWithText(FilledButton, 'Log in');
      expect(tester.widget<FilledButton>(logIn).onPressed, isNull);

      await tester.pump(const Duration(milliseconds: 1500));
      await tester.pumpAndSettle();
      expect(tester.widget<FilledButton>(logIn).onPressed, isNotNull);

      await tester.tap(logIn);
      await tester.pumpAndSettle();
      expect(find.text('On duty'), findsOneWidget);
    },
  );

  testWidgets('an administrator is told the app is for couriers', (
    WidgetTester tester,
  ) async {
    session.loginRefusals.add(const AdminAccountFailure());
    await start(tester);

    await signIn(tester);

    expect(find.textContaining('administrator account'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Log in'), findsOneWidget);
    expect(session.stored, isNull);
  });

  testWidgets(
    'a build identity does not accept asks for an update, not for a password',
    (WidgetTester tester) async {
      session.loginRefusals.add(const AppUpdateRequiredFailure());
      await start(tester);

      await signIn(tester);
      expect(find.text('Update the app'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);

      await tester.tap(find.widgetWithText(FilledButton, 'Try again'));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(FilledButton, 'Log in'), findsOneWidget);
    },
  );

  testWidgets(
    'a session identity will not renew for this build asks for an update and is kept',
    (WidgetTester tester) async {
      session.stored = _session;
      await start(tester);
      expect(find.text('On duty'), findsOneWidget);

      connection.end(const SessionUpdateRequired());
      await tester.pumpAndSettle();

      expect(find.text('Update the app'), findsOneWidget);
      expect(session.stored, _session);
    },
  );

  testWidgets('registration waits for approval', (WidgetTester tester) async {
    await start(tester);

    await tester.tap(find.text("Don't have an account? Register"));
    await tester.pumpAndSettle();
    expect(find.text('Register Driver'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), 'Budi Santoso');
    await tester.enterText(find.byType(TextField).at(1), 'budi@kinetix.test');
    await tester.enterText(find.byType(TextField).at(2), '081234567890');
    await tester.enterText(find.byType(TextField).at(3), 'fixture-password-1');
    await tester.enterText(find.byType(TextField).at(4), 'B 1234 KIN');
    await tester.enterText(find.byType(TextField).at(5), '150');

    final Finder submit = find.widgetWithText(
      FilledButton,
      'Submit Registration',
    );
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(
      find.text('Your account is awaiting admin approval'),
      findsOneWidget,
    );
  });

  testWidgets('a stored session of a pending courier waits for approval', (
    WidgetTester tester,
  ) async {
    session
      ..stored = _session
      ..pendingApproval = true;

    await start(tester);

    expect(
      find.text('Your account is awaiting admin approval'),
      findsOneWidget,
    );
  });

  testWidgets('a session that ended returns to the login', (
    WidgetTester tester,
  ) async {
    session.stored = _session;
    await start(tester);
    expect(find.text('On duty'), findsOneWidget);

    connection.end(const SessionSignedOut());
    await tester.pumpAndSettle();

    expect(find.text('Log in'), findsOneWidget);
    expect(session.stored, isNull);
  });

  testWidgets('a job taken off the courier says so', (
    WidgetTester tester,
  ) async {
    session.stored = _session;
    await start(tester);

    orders.assign(_order(OrderStatus.assigned));
    await tester.pumpAndSettle();
    orders.takeOff(const OrderId(5));
    await tester.pumpAndSettle();

    expect(find.text('Dispatch has taken this job off you'), findsOneWidget);
  });
  testWidgets(
    'a pending courier who signs in waits for approval, and is let in once approved',
    (WidgetTester tester) async {
      session.pendingApproval = true;
      await start(tester);

      await signIn(tester);
      expect(
        find.text('Your account is awaiting admin approval'),
        findsOneWidget,
      );

      await tester.tap(find.text('Check again'));
      await tester.pumpAndSettle();
      expect(find.text('Still waiting for approval.'), findsOneWidget);

      session.pendingApproval = false;
      await tester.tap(find.text('Check again'));
      await tester.pumpAndSettle();
      expect(find.text('On duty'), findsOneWidget);
    },
  );
}
