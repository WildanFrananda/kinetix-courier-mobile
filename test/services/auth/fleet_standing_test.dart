import 'package:dio/dio.dart';
import 'package:fleet_pulse_mobile/core/core.dart';
import 'package:fleet_pulse_mobile/models/models.dart';
import 'package:fleet_pulse_mobile/services/auth/driver_api.dart';
import 'package:fleet_pulse_mobile/services/auth/fleet_standing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockApi extends Mock implements DriverApi {}

void main() {
  late _MockApi api;
  late FleetStanding sut;

  const DriverProfile profile = DriverProfile(
    id: DriverId(9),
    vehiclePlate: 'B 1 ABC',
    capacityKg: 100,
    status: 'offline',
    active: true,
  );

  setUp(() {
    api = new _MockApi();
    sut = new FleetStanding(api);
  });

  DioException dioWith(int code, [Map<String, dynamic>? body]) =>
      new DioException(
        requestOptions: new RequestOptions(path: '/api/v1/matching/driver/me'),
        response: new Response<Map<String, dynamic>>(
          requestOptions: new RequestOptions(
            path: '/api/v1/matching/driver/me',
          ),
          statusCode: code,
          data: body,
        ),
      );

  Failure failureOf(Result<DriverProfile> result) =>
      (result as Err<DriverProfile>).failure;

  test('an approved courier is its profile', () async {
    when(() => api.me(any())).thenAnswer(
      (_) async => <String, dynamic>{
        'data': <String, dynamic>{
          'id': 9,
          'vehicle_plate': 'B 1 ABC',
          'capacity_kg': 100,
          'status': 'offline',
          'active': true,
        },
      },
    );

    final Result<DriverProfile> res = await sut.check('tok');

    expect((res as Ok<DriverProfile>).value, profile);
    verify(() => api.me('Bearer tok')).called(1);
  });

  test('403 pending_approval is an account not approved', () async {
    when(
      () => api.me(any()),
    ).thenThrow(dioWith(403, <String, dynamic>{'error': 'pending_approval'}));

    expect(failureOf(await sut.check('tok')), isA<PendingApprovalFailure>());
  });

  test('another 403 is a refusal of the session', () async {
    when(() => api.me(any())).thenThrow(dioWith(403));

    expect(failureOf(await sut.check('tok')), isA<AuthFailure>());
  });

  test('404 is a registration that never filed a vehicle', () async {
    when(
      () => api.me(any()),
    ).thenThrow(dioWith(404, <String, dynamic>{'error': 'no_driver_record'}));

    expect(
      failureOf(await sut.check('tok')),
      isA<RegistrationIncompleteFailure>(),
    );
  });

  test(
    'a refused token is a refusal of the session, not a wrong password',
    () async {
      when(() => api.me(any())).thenThrow(dioWith(401));

      final Failure failure = failureOf(await sut.check('tok'));

      expect(failure, isA<AuthFailure>());
      expect(failure.message, isNot(contains('password')));
    },
  );

  test('503 is an outage, never a refusal', () async {
    when(() => api.me(any())).thenThrow(
      dioWith(503, <String, dynamic>{'error': 'identity_unavailable'}),
    );

    expect(failureOf(await sut.check('tok')), isA<ServiceUnavailableFailure>());
  });

  test('no answer at all is the network', () async {
    when(() => api.me(any())).thenThrow(
      new DioException(
        requestOptions: new RequestOptions(path: '/api/v1/matching/driver/me'),
      ),
    );

    expect(failureOf(await sut.check('tok')), isA<NetworkFailure>());
  });
  test('an answer this app cannot read is not a network failure', () async {
    when(
      () => api.me(any()),
    ).thenAnswer((_) async => <String, dynamic>{'data': 'not a driver'});

    final Failure failure = failureOf(await sut.check('tok'));

    expect(failure, isNot(isA<NetworkFailure>()));
    expect(failure.message, contains('cannot read'));
  });
}
