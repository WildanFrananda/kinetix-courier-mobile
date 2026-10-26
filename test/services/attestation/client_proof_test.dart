import 'package:dio/dio.dart';
import 'package:fleet_pulse_mobile/services/attestation/client_proof.dart';
import 'package:fleet_pulse_mobile/services/attestation/client_proof_source.dart';
import 'package:fleet_pulse_mobile/services/attestation/client_proof_unavailable_exception.dart';
import 'package:flutter_test/flutter_test.dart';

class _Source implements ClientProofSource {
  final List<bool> asked = <bool>[];
  String? answer = 'token';
  Object? failure;

  @override
  Future<String?> token({required bool forceRefresh}) async {
    final Object? failing = failure;

    asked.add(forceRefresh);

    if (failing != null) {
      throw failing;
    }

    return forceRefresh ? 'fresh-$answer' : answer;
  }
}

DioException _identity(int status, String error) => new DioException(
  requestOptions: new RequestOptions(path: '/api/v1/auth/login'),
  type: DioExceptionType.badResponse,
  response: new Response<Map<String, dynamic>>(
    requestOptions: new RequestOptions(path: '/api/v1/auth/login'),
    statusCode: status,
    data: <String, dynamic>{'error': error, 'message': 'refused'},
  ),
);

void main() {
  late _Source source;
  late ClientProof sut;

  setUp(() {
    source = new _Source();
    sut = new ClientProof(source);
  });

  test('the cached token is used while identity accepts it', () async {
    final String sent = await sut.present((String proof) async => proof);

    expect(sent, 'token');
    expect(source.asked, <bool>[false]);
  });

  for (final String code in <String>[
    'CLIENT_PROOF_REQUIRED',
    'CLIENT_PROOF_INVALID',
  ]) {
    test('$code fetches one fresh token and retries once', () async {
      final List<String> sent = <String>[];

      final String answered = await sut.present((String proof) async {
        sent.add(proof);

        if (sent.length == 1) {
          throw _identity(401, code);
        }

        return 'ok';
      });

      expect(answered, 'ok');
      expect(sent, <String>['token', 'fresh-token']);
      expect(source.asked, <bool>[false, true]);
    });
  }

  test('a second refusal is not retried again', () async {
    int calls = 0;

    await expectLater(
      sut.present<String>((String proof) async {
        calls++;

        throw _identity(401, 'CLIENT_PROOF_INVALID');
      }),
      throwsA(isA<DioException>()),
    );
    expect(calls, 2);
  });

  for (final DioException other in <DioException>[
    _identity(401, 'UNAUTHORIZED'),
    _identity(503, 'CLIENT_PROOF_UNAVAILABLE'),
    _identity(400, 'UNKNOWN_CLIENT'),
  ]) {
    test(
      '${other.response?.statusCode} ${other.response?.data} is passed on untouched',
      () async {
        int calls = 0;

        await expectLater(
          sut.present<String>((String proof) async {
            calls++;

            throw other;
          }),
          throwsA(same(other)),
        );
        expect(calls, 1);
      },
    );
  }

  test(
    'a token the platform cannot give is unavailable, and nothing is sent',
    () async {
      source.failure = new Exception('Play Integrity API not available');
      int calls = 0;

      await expectLater(
        sut.present<String>((String proof) async {
          calls++;

          return proof;
        }),
        throwsA(isA<ClientProofUnavailableException>()),
      );
      expect(calls, 0);
    },
  );

  for (final String? empty in <String?>[null, '']) {
    test('a token that is "$empty" is unavailable', () async {
      source.answer = empty;

      await expectLater(
        sut.present<String>((String proof) async => proof),
        throwsA(isA<ClientProofUnavailableException>()),
      );
    });
  }
}
