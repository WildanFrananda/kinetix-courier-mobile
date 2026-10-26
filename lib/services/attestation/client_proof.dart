import 'package:dio/dio.dart';
import 'package:fleet_pulse_mobile/core/app_logger.dart';
import 'package:fleet_pulse_mobile/services/attestation/client_proof_source.dart';
import 'package:fleet_pulse_mobile/services/attestation/client_proof_unavailable_exception.dart';
import 'package:fleet_pulse_mobile/services/auth/identity_error.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class ClientProof {
  ClientProof(this._source);

  final ClientProofSource _source;

  Future<T> present<T>(Future<T> Function(String proof) send) async {
    final String first = await _token(forceRefresh: false);

    try {
      return await send(first);
    } on DioException catch (e) {
      if (!IdentityError.refusesProof(e.response)) {
        rethrow;
      }

      AppLogger.debug(
        'identity refused the proof (${IdentityError.codeOf(e.response)}); '
        'asking for a fresh one',
      );
    }

    final String fresh = await _token(forceRefresh: true);

    return send(fresh);
  }

  Future<String> _token({required bool forceRefresh}) async {
    final String? token;

    try {
      token = await _source.token(forceRefresh: forceRefresh);
    } on Object catch (e) {
      throw new ClientProofUnavailableException(e);
    }

    if (token == null || token.isEmpty) {
      throw const ClientProofUnavailableException('App Check gave no token');
    }

    return token;
  }
}
