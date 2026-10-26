import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:fleet_pulse_mobile/models/models.dart';
import 'package:fleet_pulse_mobile/services/auth/driver_api.dart';
import 'package:fleet_pulse_mobile/services/auth/identity_error.dart';
import 'package:flutter_test/flutter_test.dart';

class _Answer implements HttpClientAdapter {
  _Answer(this.status, this.body, this.headers);

  final int status;
  final Map<String, dynamic> body;
  final Map<String, List<String>> headers;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
        ...headers,
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Future<Response<dynamic>?> _refusal(
  int status,
  Map<String, dynamic> body, [
  Map<String, List<String>> headers = const <String, List<String>>{},
]) async {
  final DriverApi api = new DriverApi(
    new Dio(new BaseOptions(baseUrl: 'https://edge.test'))
      ..httpClientAdapter = new _Answer(status, body, headers),
  );

  try {
    await api.login('proof', const LoginRequest(email: 'e', password: 'p'));
  } on DioException catch (e) {
    return e.response;
  }

  return null;
}

void main() {
  test(
    "identity's SIGN_IN_DELAYED is read from the body it sends with Retry-After",
    () async {
      final Response<dynamic>? response = await _refusal(
        429,
        <String, dynamic>{
          'error': 'SIGN_IN_DELAYED',
          'message': 'Too many unsuccessful sign-in attempts for this account.',
          'retryAfterSeconds': 16,
          'traceId': 'trace-1',
        },
        <String, List<String>>{
          'Retry-After': <String>['16'],
        },
      );

      expect(IdentityError.delayOf(response), const Duration(seconds: 16));
    },
  );

  test('a 429 with Retry-After alone is read from the header', () async {
    final Response<dynamic>? response = await _refusal(
      429,
      <String, dynamic>{'statusCode': 429, 'message': 'Too Many Requests'},
      <String, List<String>>{
        'retry-after': <String>['42'],
      },
    );

    expect(IdentityError.delayOf(response), const Duration(seconds: 42));
  });

  test('a 429 that names no wait has none', () async {
    final Response<dynamic>? response = await _refusal(429, <String, dynamic>{
      'statusCode': 429,
      'message': 'Too Many Requests',
    });

    expect(IdentityError.delayOf(response), isNull);
  });

  test('only a 429 is a delay', () async {
    final Response<dynamic>? response = await _refusal(
      401,
      <String, dynamic>{'message': 'Invalid email or password credentials'},
      <String, List<String>>{
        'retry-after': <String>['5'],
      },
    );

    expect(IdentityError.delayOf(response), isNull);
  });

  test(
    'the exhausted challenge is told from a wrong code by its message alone',
    () async {
      final Response<dynamic>? exhausted =
          await _refusal(401, <String, dynamic>{
            'statusCode': 401,
            'message': 'This challenge allows no more attempts; sign in again',
            'error': 'Unauthorized',
            'traceId': 'trace-1',
          });
      final Response<dynamic>? wrong = await _refusal(401, <String, dynamic>{
        'statusCode': 401,
        'message': 'That code is not valid',
        'error': 'Unauthorized',
        'traceId': 'trace-2',
      });

      expect(IdentityError.challengeExhausted(exhausted), isTrue);
      expect(IdentityError.wrongCode(exhausted), isFalse);
      expect(IdentityError.wrongCode(wrong), isTrue);
      expect(IdentityError.challengeExhausted(wrong), isFalse);
    },
  );
}
