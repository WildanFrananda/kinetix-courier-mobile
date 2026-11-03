import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:fleet_pulse_mobile/core/core.dart';
import 'package:fleet_pulse_mobile/models/models.dart';
import 'package:fleet_pulse_mobile/repositories/credential_repository_impl.dart';
import 'package:fleet_pulse_mobile/services/auth/session_renewer.dart';
import 'package:fleet_pulse_mobile/services/auth/token_store.dart';
import 'package:fleet_pulse_mobile/services/seal/holder_runtime.dart';
import 'package:fleet_pulse_mobile/services/seal/holder_runtime_exception.dart';
import 'package:fleet_pulse_mobile/services/seal/holder_vault.dart';
import 'package:fleet_pulse_mobile/services/seal/seal_api.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockApi extends Mock implements SealApi {}

class _MockStore extends Mock implements TokenStore {}

class _MockRenewer extends Mock implements SessionRenewer {}

class _MockRuntime extends Mock implements HolderRuntime {}

const String registry =
    '5d951a33d630fb5c498577b3e051a639dc7b529472ea8c86d7d11b2883b60c2e';
const String rowId =
    'aa11aa11aa11aa11aa11aa11aa11aa11aa11aa11aa11aa11aa11aa11aa11aa11';
const String challenge =
    'cc00cc00cc00cc00cc00cc00cc00cc00cc00cc00cc00cc00cc00cc00cc00cc00';

Map<String, dynamic> credentialBody({
  Map<String, dynamic>? registryPlacement,
}) => <String, dynamic>{
  'id': '0b0e7f6e-1b7a-4c5e-9c1e-1f2a3b4c5d6e',
  'status': registryPlacement == null ? 'pending' : 'issued',
  'issueDay': 20760,
  'credential': <String, dynamic>{
    'classId': 'ab' * 32,
    'attributes': <String>['120', '470', '95', '20760'],
    'salt': 'cd' * 32,
  },
  'holderPublicKey': '987654321',
  'registry': registryPlacement,
};

const Map<String, dynamic> placement = <String, dynamic>{
  'generation': 1,
  'contractAddress': registry,
  'leafIndex': '7',
  'txId': '00tx',
};

final Map<String, dynamic> snapshot = <String, dynamic>{
  'generation': 1,
  'networkId': 'preprod',
  'contractAddress': registry,
  'contractState': '00',
  'zswapChainState': '01',
  'ledgerParameters': '02',
  'readAt': '2026-11-03T03:00:00.000Z',
};

final Map<String, dynamic> predicates = <String, dynamic>{
  'registry': <String, dynamic>{'generation': 1, 'contractAddress': registry},
  'predicates': <dynamic>[
    <String, dynamic>{
      'id': '00000000-0000-4000-8000-0000000000a1',
      'label': 'Experienced courier',
      'minimums': <String, dynamic>{
        'deliveries': 100,
        'ratingHundredths': 450,
        'daysActive': 90,
      },
      'rows': <dynamic>[
        <String, dynamic>{
          'id': rowId,
          'minimumIssueDate': '2026-09-29',
          'current': true,
          'placed': true,
        },
      ],
    },
  ],
};

String request({
  String scheme = 'kinetix-seal',
  String answer = 'https://verify.example/seal/answer',
  String to = registry,
  String predicate = rowId,
}) =>
    '$scheme:present?v=1&r=$to&p=$predicate&c=$challenge&a=${Uri.encodeComponent(answer)}';

DioException refused(int code, [String? error]) => new DioException(
  requestOptions: new RequestOptions(path: '/api/v1/seal'),
  response: new Response<Map<String, dynamic>>(
    requestOptions: new RequestOptions(path: '/api/v1/seal'),
    statusCode: code,
    data: error == null ? null : <String, dynamic>{'error': error},
  ),
);

void main() {
  late _MockApi api;
  late _MockStore tokens;
  late _MockRenewer renewer;
  late _MockRuntime runtime;
  late HolderVault vault;
  late CredentialRepositoryImpl repository;

  const DriverSession session = DriverSession(
    driverId: null,
    token: 'access-1',
    refreshToken: 'refresh-1',
  );

  setUpAll(() {
    registerFallbackValue(Uri.parse('https://example.invalid'));
  });

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    api = new _MockApi();
    tokens = new _MockStore();
    renewer = new _MockRenewer();
    runtime = new _MockRuntime();
    vault = new HolderVault(const FlutterSecureStorage());
    repository = new CredentialRepositoryImpl(
      api,
      tokens,
      renewer,
      vault,
      runtime,
    );

    when(() => tokens.read()).thenAnswer((_) async => session);
    when(() => api.snapshot()).thenAnswer((_) async => snapshot);
    when(() => api.predicates()).thenAnswer((_) async => predicates);
    when(() => api.holder()).thenAnswer(
      (_) async => <String, dynamic>{
        'digest': 'd' * 64,
        'entry': '/api/v1/seal/holder/${'d' * 64}/index.html',
      },
    );
    when(() => runtime.start(any())).thenAnswer((_) async {});
    when(
      () => runtime.call('prepare', any()),
    ).thenAnswer((_) async => <String, String>{'ok': 'true'});
    when(() => runtime.call('holderPublicKey', any())).thenAnswer(
      (_) async => <String, String>{
        'ok': 'true',
        'holderPublicKey': '987654321',
      },
    );
  });

  group('asking for a credential', () {
    test(
      'sends only the holder key computed on the phone, and keeps what seal answers',
      () async {
        when(
          () => api.requestCredential(any(), any()),
        ).thenAnswer((_) async => credentialBody());

        final Result<CourierCredential> requested = await repository.request();
        final CourierCredential credential =
            (requested as Ok<CourierCredential>).value;
        final String secret = await vault.holderSecret();

        expect(credential.standing, CredentialStanding.pending);
        expect(credential.deliveries, 120);
        expect(credential.placement, isNull);
        expect(secret, matches(new RegExp(r'^[0-9a-f]{64}$')));
        verify(
          () => runtime.call('holderPublicKey', <String>[secret]),
        ).called(1);
        verify(
          () => api.requestCredential('Bearer access-1', <String, dynamic>{
            'holderPublicKey': '987654321',
          }),
        ).called(1);
        expect(await vault.credential(), isNotNull);
      },
    );

    test("names seal's refusal, such as a courier with no delivery", () async {
      when(
        () => api.requestCredential(any(), any()),
      ).thenThrow(refused(409, 'NO_DELIVERIES'));

      final Result<CourierCredential> requested = await repository.request();

      expect(
        (requested as Err<CourierCredential>).failure,
        isA<CredentialFailure>(),
      );
      expect(
        requested.failure.message,
        'A credential needs at least one delivered job.',
      );
    });

    test('renews an expired session once and asks again', () async {
      int asked = 0;

      when(() => api.requestCredential(any(), any())).thenAnswer((
        Invocation invocation,
      ) async {
        asked += 1;

        if (invocation.positionalArguments.first == 'Bearer access-1') {
          throw refused(401);
        }

        return credentialBody();
      });
      when(() => renewer.renew()).thenAnswer(
        (_) async => const Ok<DriverSession>(
          DriverSession(driverId: null, token: 'access-2', refreshToken: 'r'),
        ),
      );

      expect(await repository.request(), isA<Ok<CourierCredential>>());
      expect(asked, 2);
    });

    test('says the holder failed rather than sending a wrong key', () async {
      when(
        () => runtime.call('holderPublicKey', any()),
      ).thenThrow(const HolderRuntimeException('boom'));

      final Result<CourierCredential> requested = await repository.request();

      expect(
        (requested as Err<CourierCredential>).failure.message,
        'The credential could not be shown. Try again.',
      );
      verifyNever(() => api.requestCredential(any(), any()));
    });

    test(
      'refuses an answer it cannot read rather than inventing numbers',
      () async {
        when(() => api.requestCredential(any(), any())).thenAnswer(
          (_) async => <String, dynamic>{
            ...credentialBody(),
            'issueDay': 'soon',
          },
        );

        expect(
          (await repository.request() as Err<CourierCredential>).failure,
          isA<UnreadableAnswerFailure>(),
        );
        expect(await vault.credential(), isNull);
      },
    );
  });

  group('the public state the phone proves against', () {
    test('is fetched at most every six hours unless forced', () async {
      await repository.refreshPublicState(force: false);
      await repository.refreshPublicState(force: false);
      await repository.refreshPublicState(force: true);

      verify(() => api.snapshot()).called(2);
      expect(await vault.holderEntry(), endsWith('/index.html'));
    });
  });

  group("reading a verifier's request", () {
    setUp(() async {
      await repository.refreshPublicState(force: true);
    });

    test(
      "shows what is asked from this phone's own copy of the approved predicates",
      () async {
        final Result<PresentationOffer> offer = await repository.offerFor(
          request(),
        );
        final PresentationOffer value = (offer as Ok<PresentationOffer>).value;

        expect(value.label, 'Experienced courier');
        expect(value.deliveries, 100);
        expect(value.ratingHundredths, 450);
        expect(value.issuedSince, '2026-09-29');
        expect(value.answerUrl.host, 'verify.example');
      },
    );

    test(
      'refuses codes that are not requests, unsafe answers, other registries and unknown asks',
      () async {
        Future<String> reasonOf(String scanned) async =>
            ((await repository.offerFor(scanned) as Err<PresentationOffer>)
                        .failure
                    as CredentialFailure)
                .reason;

        expect(await reasonOf('https://example.com'), 'not_a_request');
        expect(await reasonOf(request(scheme: 'other')), 'not_a_request');
        expect(
          await reasonOf(request(answer: 'http://verify.example/answer')),
          'insecure_answer',
        );
        expect(await reasonOf(request(to: 'ee' * 32)), 'other_registry');
        expect(
          await reasonOf(request(predicate: 'bb' * 32)),
          'unknown_predicate',
        );
      },
    );
  });

  group('presenting', () {
    late PresentationOffer offer;

    setUp(() async {
      await repository.refreshPublicState(force: true);
      offer =
          (await repository.offerFor(request()) as Ok<PresentationOffer>).value;
    });

    test('waits until the credential is in the registry', () async {
      await vault.keepCredential(jsonEncode(credentialBody()));

      final Result<PresentedAnswer> answer = await repository.present(offer);

      expect(
        ((answer as Err<PresentedAnswer>).failure as CredentialFailure).reason,
        'not_issued_yet',
      );
    });

    test(
      'proves on the phone and calls seal for nothing while presenting',
      () async {
        await vault.keepCredential(
          jsonEncode(credentialBody(registryPlacement: placement)),
        );
        clearInteractions(api);
        when(() => runtime.call('present', any())).thenAnswer(
          (_) async => <String, String>{'ok': 'true', 'transaction': '0a0b0c'},
        );

        final Result<PresentedAnswer> answer = await repository.present(offer);
        final PresentedAnswer value = (answer as Ok<PresentedAnswer>).value;
        final List<String> sent =
            verify(() => runtime.call('present', captureAny())).captured.single
                as List<String>;
        final Map<String, dynamic> presentation =
            jsonDecode(sent.single) as Map<String, dynamic>;

        expect(
          value.link.toString(),
          'https://verify.example/seal/answer#CgsM',
        );
        expect(value.frames.single, startsWith('KSP1:'));
        expect(presentation['leafIndex'], '7');
        expect(presentation['challenge'], challenge);
        expect(presentation['predicateId'], rowId);
        expect(
          (presentation['snapshot'] as Map<String, dynamic>)['contractAddress'],
          registry,
        );
        verifyZeroInteractions(api);
      },
    );

    test('names a holder failure without losing the request', () async {
      await vault.keepCredential(
        jsonEncode(credentialBody(registryPlacement: placement)),
      );
      when(() => runtime.call('present', any())).thenThrow(
        const HolderRuntimeException(
          'the credential does not meet the predicate',
        ),
      );

      expect(
        ((await repository.present(offer)) as Err<PresentedAnswer>).failure,
        isA<CredentialFailure>(),
      );
    });
  });

  group('the current credential', () {
    test('is none until one was asked for', () async {
      expect(
        (await repository.current() as Ok<CourierCredential?>).value,
        isNull,
      );
    });

    test(
      'is refreshed from seal, and kept as it was when seal cannot be reached',
      () async {
        await vault.keepCredential(jsonEncode(credentialBody()));
        when(
          () => api.credential(any(), any()),
        ).thenAnswer((_) async => credentialBody(registryPlacement: placement));

        final CourierCredential? fresh =
            (await repository.current() as Ok<CourierCredential?>).value;

        expect(fresh?.standing, CredentialStanding.issued);
        expect(fresh?.placement?.leafIndex, '7');

        when(() => api.credential(any(), any())).thenThrow(
          new DioException(
            requestOptions: new RequestOptions(path: '/x'),
            type: DioExceptionType.connectionError,
          ),
        );

        expect(
          (await repository.current() as Ok<CourierCredential?>)
              .value
              ?.standing,
          CredentialStanding.issued,
        );
      },
    );
  });
}
