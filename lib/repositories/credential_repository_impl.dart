import 'dart:async';
import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:kinetix_courier/config/app_config.dart';
import 'package:kinetix_courier/core/core.dart';
import 'package:kinetix_courier/models/models.dart';
import 'package:kinetix_courier/repositories/credential_repository.dart';
import 'package:kinetix_courier/services/auth/session_renewer.dart';
import 'package:kinetix_courier/services/auth/token_store.dart';
import 'package:kinetix_courier/services/seal/holder_runtime.dart';
import 'package:kinetix_courier/services/seal/holder_runtime_exception.dart';
import 'package:kinetix_courier/services/seal/holder_vault.dart';
import 'package:kinetix_courier/services/seal/presentation_frames.dart';
import 'package:kinetix_courier/services/seal/seal_api.dart';

@LazySingleton(as: CredentialRepository)
class CredentialRepositoryImpl implements CredentialRepository {
  CredentialRepositoryImpl(
    this._api,
    this._tokens,
    this._renewer,
    this._vault,
    this._runtime,
  );

  static const Duration publicStateAge = Duration(hours: 6);

  static final RegExp _field32 = new RegExp(r'^[0-9a-f]{64}$');

  static final RegExp _hex = new RegExp(r'^([0-9a-f]{2})+$');

  final SealApi _api;

  final TokenStore _tokens;

  final SessionRenewer _renewer;

  final HolderVault _vault;

  final HolderRuntime _runtime;

  @override
  Future<Result<CourierCredential?>> current() async {
    final String? stored = await _vault.credential();

    if (stored == null) {
      return const Ok<CourierCredential?>(null);
    }

    final Map<String, dynamic>? known = _objectOf(jsonDecode(stored));

    if (known == null) {
      return const Ok<CourierCredential?>(null);
    }

    final Result<dynamic> fresh = await _authorized(
      (String bearer) => _api.credential(bearer, '${known['id']}'),
    );

    if (fresh case Ok<dynamic>(:final dynamic value)) {
      final Map<String, dynamic>? body = _objectOf(value);

      final CourierCredential? parsed = body == null
          ? null
          : _credentialOf(body);

      if (body != null && parsed != null) {
        await _vault.keepCredential(jsonEncode(body));

        return new Ok<CourierCredential?>(await _asProvable(parsed));
      }
    }

    if (fresh case Err<dynamic>(
      :final Failure failure,
    ) when failure is AuthFailure) {
      return new Err<CourierCredential?>(failure);
    }

    final CourierCredential? kept = _credentialOf(known);

    return new Ok<CourierCredential?>(
      kept == null ? null : await _asProvable(kept),
    );
  }

  @override
  Future<Result<CourierCredential>> request() async {
    final Result<Unit> prepared = await prepareHolder();

    if (prepared case Err<Unit>(:final Failure failure)) {
      return new Err<CourierCredential>(failure);
    }

    final String holderPublicKey;

    try {
      final Map<String, String> answer = await _runtime.call(
        'holderPublicKey',
        <String>[await _vault.holderSecret()],
      );

      holderPublicKey = answer['holderPublicKey'] ?? '';
    } on HolderRuntimeException {
      return const Err<CourierCredential>(CredentialFailure('holder_failed'));
    }

    final Result<dynamic> answered = await _authorized(
      (String bearer) => _api.requestCredential(bearer, <String, dynamic>{
        'holderPublicKey': holderPublicKey,
      }),
    );

    switch (answered) {
      case Ok<dynamic>(:final dynamic value):
        final Map<String, dynamic>? body = _objectOf(value);
        final CourierCredential? parsed = body == null
            ? null
            : _credentialOf(body);

        if (body == null || parsed == null) {
          return const Err<CourierCredential>(
            UnreadableAnswerFailure(
              'seal answered in a form this app cannot read',
            ),
          );
        }

        await _vault.keepCredential(jsonEncode(body));

        return new Ok<CourierCredential>(await _asProvable(parsed));
      case Err<dynamic>(:final Failure failure):
        return new Err<CourierCredential>(failure);
    }
  }

  @override
  Future<Result<Unit>> refreshPublicState({required bool force}) async {
    final DateTime? refreshedAt = await _vault.publicStateRefreshedAt();

    if (!force &&
        refreshedAt != null &&
        clock.now().difference(refreshedAt) < publicStateAge) {
      return const Ok<Unit>(Unit.unit);
    }

    try {
      final dynamic snapshot = await _api.snapshot();
      final dynamic predicates = await _api.predicates();
      final Map<String, dynamic>? holder = _objectOf(await _api.holder());
      final Object? entry = holder?['entry'];

      if (entry is! String || !entry.startsWith('/')) {
        return const Err<Unit>(
          UnreadableAnswerFailure(
            'seal answered in a form this app cannot read',
          ),
        );
      }

      await _vault.keepPublicState(
        snapshot: jsonEncode(snapshot),
        predicates: jsonEncode(predicates),
        holderEntry: '${AppConfig.httpBase}$entry',
        at: clock.now(),
      );

      return const Ok<Unit>(Unit.unit);
    } on DioException catch (e) {
      return new Err<Unit>(_failureOf(e));
    }
  }

  @override
  Future<Result<Unit>> prepareHolder() async {
    String? entry = await _vault.holderEntry();

    if (entry == null) {
      final Result<Unit> refreshed = await refreshPublicState(force: true);

      if (refreshed case Err<Unit>(:final Failure failure)) {
        return new Err<Unit>(failure);
      }

      entry = await _vault.holderEntry();
    }

    if (entry == null) {
      return const Err<Unit>(CredentialFailure('holder_failed'));
    }

    try {
      await _runtime.start(Uri.parse(entry));
      await _runtime.call('prepare', const <String>[]);

      return const Ok<Unit>(Unit.unit);
    } on HolderRuntimeException {
      return const Err<Unit>(CredentialFailure('holder_failed'));
    }
  }

  @override
  Future<Result<PresentationOffer>> offerFor(String scanned) async {
    final Uri? request = Uri.tryParse(scanned.trim());
    final Map<String, String> query =
        request?.queryParameters ?? const <String, String>{};
    final String registry = query['r'] ?? '';
    final String predicateId = query['p'] ?? '';
    final String challenge = query['c'] ?? '';

    if (request == null ||
        request.scheme != 'kinetix-seal' ||
        request.path != 'present' ||
        query['v'] != '1' ||
        !_hex.hasMatch(registry) ||
        !_field32.hasMatch(predicateId) ||
        !_field32.hasMatch(challenge)) {
      return const Err<PresentationOffer>(CredentialFailure('not_a_request'));
    }

    final Uri? answerUrl = Uri.tryParse(query['a'] ?? '');

    if (answerUrl == null ||
        answerUrl.scheme != 'https' ||
        answerUrl.host.isEmpty) {
      return const Err<PresentationOffer>(CredentialFailure('insecure_answer'));
    }

    final Map<String, dynamic>? snapshot = _objectOf(
      _decoded(await _vault.snapshot()),
    );
    final Map<String, dynamic>? listing = _objectOf(
      _decoded(await _vault.predicates()),
    );

    if (snapshot == null || listing == null) {
      return const Err<PresentationOffer>(
        CredentialFailure('unknown_predicate'),
      );
    }

    if (snapshot['contractAddress'] != registry) {
      return const Err<PresentationOffer>(CredentialFailure('other_registry'));
    }

    final Object? predicates = listing['predicates'];

    for (final Object? entry
        in predicates is List<dynamic> ? predicates : const <Object?>[]) {
      final Map<String, dynamic>? predicate = _objectOf(entry);
      final Map<String, dynamic>? minimums = _objectOf(predicate?['minimums']);
      final Object? rows = predicate?['rows'];

      for (final Object? candidate
          in rows is List<dynamic> ? rows : const <Object?>[]) {
        final Map<String, dynamic>? row = _objectOf(candidate);

        if (predicate == null ||
            minimums == null ||
            row == null ||
            row['id'] != predicateId) {
          continue;
        }

        final Object? label = predicate['label'];
        final Object? issuedSince = row['minimumIssueDate'];
        final int? deliveries = _intOf(minimums['deliveries']);
        final int? ratingHundredths = _intOf(minimums['ratingHundredths']);
        final int? daysActive = _intOf(minimums['daysActive']);

        if (label is! String ||
            issuedSince is! String ||
            deliveries == null ||
            ratingHundredths == null ||
            daysActive == null) {
          return const Err<PresentationOffer>(
            UnreadableAnswerFailure(
              'seal answered in a form this app cannot read',
            ),
          );
        }

        return new Ok<PresentationOffer>(
          new PresentationOffer(
            contractAddress: registry,
            predicateId: predicateId,
            challenge: challenge,
            answerUrl: answerUrl,
            label: label,
            deliveries: deliveries,
            ratingHundredths: ratingHundredths,
            daysActive: daysActive,
            issuedSince: issuedSince,
          ),
        );
      }
    }

    return const Err<PresentationOffer>(CredentialFailure('unknown_predicate'));
  }

  @override
  Future<Result<PresentedAnswer>> present(PresentationOffer offer) async {
    final Map<String, dynamic>? credential = _objectOf(
      _decoded(await _vault.credential()),
    );
    final Map<String, dynamic>? snapshot = _objectOf(
      _decoded(await _vault.snapshot()),
    );
    final String? entry = await _vault.holderEntry();
    final Map<String, dynamic>? placement = _objectOf(credential?['registry']);

    if (credential == null || snapshot == null || entry == null) {
      return const Err<PresentedAnswer>(CredentialFailure('no_credential'));
    }

    if (placement == null ||
        placement['contractAddress'] != offer.contractAddress) {
      return const Err<PresentedAnswer>(CredentialFailure('not_issued_yet'));
    }

    final Map<String, Object?> presentation = <String, Object?>{
      'snapshot': snapshot,
      'holderSecret': await _vault.holderSecret(),
      'credential': credential['credential'],
      'leafIndex': placement['leafIndex'],
      'challenge': offer.challenge,
      'predicateId': offer.predicateId,
    };

    try {
      await _runtime.start(Uri.parse(entry));

      final Map<String, String> answer = await _runtime.call(
        'present',
        <String>[jsonEncode(presentation)],
      );
      final String transaction = answer['transaction'] ?? '';

      if (!_hex.hasMatch(transaction)) {
        return const Err<PresentedAnswer>(CredentialFailure('holder_failed'));
      }

      return new Ok<PresentedAnswer>(
        new PresentedAnswer(
          frames: PresentationFrames.of(transaction),
          link: PresentationFrames.link(
            offer.answerUrl,
            offer.challenge,
            transaction,
          ),
        ),
      );
    } on HolderRuntimeException {
      return const Err<PresentedAnswer>(CredentialFailure('holder_failed'));
    }
  }

  Future<CourierCredential> _asProvable(CourierCredential credential) async {
    final CredentialPlacement? placement = credential.placement;

    if (credential.standing != CredentialStanding.issued || placement == null) {
      return credential;
    }

    final String key = '${placement.contractAddress}:${placement.leafIndex}';

    if (await _vault.coveredPlacement() == key) {
      return credential;
    }

    final CourierCredential waiting = credential.copyWith(
      standing: CredentialStanding.pending,
    );
    final Result<Unit> refreshed = await refreshPublicState(force: true);

    if (refreshed is Err<Unit>) {
      return waiting;
    }

    final Map<String, dynamic>? snapshot = _objectOf(
      _decoded(await _vault.snapshot()),
    );
    final Object? readAt = snapshot?['readAt'];

    if (readAt is! String ||
        snapshot?['contractAddress'] != placement.contractAddress) {
      return waiting;
    }

    final String? firstRead = await _vault.firstReadAfterIssue(key);

    if (firstRead == null) {
      await _vault.keepFirstReadAfterIssue(key, readAt);

      return waiting;
    }

    if (firstRead == readAt) {
      return waiting;
    }

    await _vault.keepCoveredPlacement(key);

    return credential;
  }

  Future<Result<dynamic>> _authorized(
    Future<dynamic> Function(String bearer) call,
  ) async {
    final DriverSession? session = await _tokens.read();

    if (session == null) {
      return const Err<dynamic>(AuthFailure());
    }

    try {
      return new Ok<dynamic>(await call('Bearer ${session.token}'));
    } on DioException catch (e) {
      if (e.response?.statusCode != 401) {
        return new Err<dynamic>(_failureOf(e));
      }
    }

    switch (await _renewer.renew()) {
      case Ok<DriverSession>(:final DriverSession value):
        try {
          return new Ok<dynamic>(await call('Bearer ${value.token}'));
        } on DioException catch (e) {
          return new Err<dynamic>(
            e.response?.statusCode == 401 ? const AuthFailure() : _failureOf(e),
          );
        }
      case Err<DriverSession>(:final Failure failure):
        return new Err<dynamic>(failure);
    }
  }

  Failure _failureOf(DioException e) {
    final Object? code = _objectOf(e.response?.data)?['error'];

    if (code is String && e.response != null) {
      return new CredentialFailure(code);
    }

    return switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.sendTimeout => const TimeoutFailure(),
      _ => const NetworkFailure(),
    };
  }

  CourierCredential? _credentialOf(Map<String, dynamic> body) {
    final Map<String, dynamic>? credential = _objectOf(body['credential']);
    final Object? attributes = credential?['attributes'];
    final List<int?> values = attributes is List<dynamic>
        ? attributes.map(_intOf).toList()
        : const <int?>[];
    final Map<String, dynamic>? registry = _objectOf(body['registry']);
    final int? issueDay = _intOf(body['issueDay']);
    final Object? id = body['id'];
    final CredentialStanding? standing = CredentialStanding.values
        .where(
          (CredentialStanding candidate) => candidate.name == body['status'],
        )
        .firstOrNull;

    if (id is! String ||
        standing == null ||
        issueDay == null ||
        values.length != 4 ||
        values.contains(null)) {
      return null;
    }

    final CredentialPlacement? placement = registry == null
        ? null
        : _placementOf(registry);

    if (registry != null && placement == null) {
      return null;
    }

    return new CourierCredential(
      id: id,
      standing: standing,
      issueDay: issueDay,
      deliveries: values[0]!,
      ratingHundredths: values[1]!,
      daysActive: values[2]!,
      placement: placement,
    );
  }

  CredentialPlacement? _placementOf(Map<String, dynamic> registry) {
    final int? generation = _intOf(registry['generation']);
    final Object? contractAddress = registry['contractAddress'];
    final Object? leafIndex = registry['leafIndex'];

    if (generation == null ||
        contractAddress is! String ||
        leafIndex is! String) {
      return null;
    }

    return new CredentialPlacement(
      generation: generation,
      contractAddress: contractAddress,
      leafIndex: leafIndex,
    );
  }

  static Object? _decoded(String? stored) {
    return stored == null ? null : jsonDecode(stored);
  }

  static Map<String, dynamic>? _objectOf(Object? value) {
    return value is Map<String, dynamic> ? value : null;
  }

  static int? _intOf(Object? value) {
    return switch (value) {
      final int number => number,
      final String text => int.tryParse(text),
      _ => null,
    };
  }
}
