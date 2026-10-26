import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:fleet_pulse_mobile/models/models.dart';
import 'package:fleet_pulse_mobile/services/auth/driver_api.dart';
import 'package:flutter_test/flutter_test.dart';

class _Recorder implements HttpClientAdapter {
  final List<RequestOptions> requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);

    return ResponseBody.fromString(
      jsonEncode(<String, dynamic>{}),
      200,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late _Recorder recorder;
  late DriverApi sut;

  setUp(() {
    recorder = new _Recorder();
    sut = new DriverApi(
      new Dio(new BaseOptions(baseUrl: 'https://edge.test'))
        ..httpClientAdapter = recorder,
    );
  });

  Map<String, dynamic> headersOf(String path) => recorder.requests
      .singleWhere((RequestOptions r) => r.path == path)
      .headers;

  test(
    'login, the second factor, registration and refresh name the app and carry its proof',
    () async {
      await sut.login('proof-1', const LoginRequest(email: 'e', password: 'p'));
      await sut.verifyTwoFactor(
        'proof-2',
        const TwoFactorVerifyRequest(challengeToken: 'c', code: '123456'),
      );
      await sut.registerCourier(
        'proof-3',
        const RegisterCourierRequest(
          email: 'e',
          password: 'p',
          fullName: 'Budi',
          phoneNumber: '081200000000',
          vehiclePlate: 'B 1',
          capacityKg: 10,
        ),
      );
      await sut.refresh('proof-4', const RefreshRequest(refreshToken: 'r'));

      final Map<String, String> proofs = <String, String>{
        '/api/v1/auth/login': 'proof-1',
        '/api/v1/auth/2fa/verify': 'proof-2',
        '/api/v1/couriers/register': 'proof-3',
        '/api/v1/auth/refresh': 'proof-4',
      };

      for (final MapEntry<String, String> call in proofs.entries) {
        final Map<String, dynamic> headers = headersOf(call.key);

        expect(headers['X-Kinetix-Client'], 'courier-app', reason: call.key);
        expect(headers['X-Firebase-AppCheck'], call.value, reason: call.key);
      }
    },
  );

  test('logout and the fleet question carry no client proof', () async {
    await sut.logout('Bearer a', const LogoutRequest(refreshToken: 'r'));
    await sut.me('Bearer a');

    for (final String path in <String>[
      '/api/v1/auth/logout',
      '/api/v1/matching/driver/me',
    ]) {
      final Map<String, dynamic> headers = headersOf(path);

      expect(headers.containsKey('X-Firebase-AppCheck'), isFalse);
      expect(headers.containsKey('X-Kinetix-Client'), isFalse);
    }
  });
}
