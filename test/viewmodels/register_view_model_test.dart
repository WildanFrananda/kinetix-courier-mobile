import 'package:fleet_pulse_mobile/core/failure.dart';
import 'package:fleet_pulse_mobile/core/result.dart';
import 'package:fleet_pulse_mobile/models/ids.dart';
import 'package:fleet_pulse_mobile/models/driver_session.dart';
import 'package:fleet_pulse_mobile/repositories/session_repository.dart';
import 'package:fleet_pulse_mobile/routes/app_route.dart';
import 'package:fleet_pulse_mobile/routes/app_router_state.dart';
import 'package:fleet_pulse_mobile/viewmodels/register_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSession extends Mock implements SessionRepository {}

void main() {
  late _MockSession session;
  late AppRouterState router;
  late RegisterViewModel sut;

  void fill(RegisterViewModel vm) {
    vm
      ..setEmail('driver@kinetix.test')
      ..setName('Budi')
      ..setPhone('0812')
      ..setPassword('supersecret1')
      ..setVehiclePlate('B 1234 XY')
      ..setCapacityKg('200');
  }

  void stubRegister(Result<DriverSession> answer) {
    when(
      () => session.register(
        email: any(named: 'email'),
        name: any(named: 'name'),
        phone: any(named: 'phone'),
        password: any(named: 'password'),
        vehiclePlate: any(named: 'vehiclePlate'),
        capacityKg: any(named: 'capacityKg'),
      ),
    ).thenAnswer((_) async => answer);
  }

  void verifyNeverRegistered() {
    verifyNever(
      () => session.register(
        email: any(named: 'email'),
        name: any(named: 'name'),
        phone: any(named: 'phone'),
        password: any(named: 'password'),
        vehiclePlate: any(named: 'vehiclePlate'),
        capacityKg: any(named: 'capacityKg'),
      ),
    );
  }

  setUp(() {
    session = new _MockSession();
    router = new AppRouterState();
    sut = new RegisterViewModel(router, session);
  });

  test('empty fields set an error and skip register', () async {
    await sut.submit();
    expect(sut.error, isNotNull);
    verifyNeverRegistered();
  });

  test('an email without an @ is rejected', () async {
    fill(sut);
    sut.setEmail('driver.kinetix.test');
    await sut.submit();
    expect(sut.error, contains('email'));
    verifyNeverRegistered();
  });

  test('short password is rejected', () async {
    fill(sut);
    sut.setPassword('short');
    await sut.submit();
    expect(sut.error, contains('12'));
    verifyNeverRegistered();
  });

  for (final String bad in <String>['not a number', '0', '-5']) {
    test('capacity "$bad" is rejected', () async {
      fill(sut);
      sut.setCapacityKg(bad);
      await sut.submit();
      expect(sut.error, contains('Capacity'));
      verifyNeverRegistered();
    });
  }

  test('successful register surfaces a message and clears the error', () async {
    stubRegister(
      const Ok<DriverSession>(
        DriverSession(driverId: DriverId(1), token: 't', refreshToken: 'r'),
      ),
    );
    fill(sut);
    await sut.submit();
    expect(sut.successMessage, isNotNull);
    expect(sut.error, isNull);
  });

  test('successful register routes to the waiting screen', () async {
    stubRegister(
      const Ok<DriverSession>(
        DriverSession(driverId: DriverId(1), token: 't', refreshToken: 'r'),
      ),
    );
    fill(sut);
    await sut.submit();

    expect(router.stack.last, isA<PendingApprovalRoute>());
  });

  test('a failed register stays put', () async {
    stubRegister(const Err<DriverSession>(ChannelFailure('nope')));
    fill(sut);
    await sut.submit();

    expect(router.stack.last, isNot(isA<PendingApprovalRoute>()));
  });

  test('the email reaches the repository as typed', () async {
    stubRegister(
      const Ok<DriverSession>(
        DriverSession(driverId: DriverId(1), token: 't', refreshToken: 'r'),
      ),
    );
    fill(sut);
    await sut.submit();

    final String sent =
        verify(
              () => session.register(
                email: captureAny(named: 'email'),
                name: any(named: 'name'),
                phone: any(named: 'phone'),
                password: any(named: 'password'),
                vehiclePlate: any(named: 'vehiclePlate'),
                capacityKg: any(named: 'capacityKg'),
              ),
            ).captured.single
            as String;
    expect(sent, 'driver@kinetix.test');
  });

  test('failed register surfaces the failure', () async {
    stubRegister(const Err<DriverSession>(ChannelFailure('name taken')));
    fill(sut);
    await sut.submit();
    expect(sut.error, 'name taken');
  });
}
