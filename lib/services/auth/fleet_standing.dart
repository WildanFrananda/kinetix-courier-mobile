import 'dart:io' show HttpStatus;

import 'package:dio/dio.dart';
import 'package:fleet_pulse_mobile/core/core.dart';
import 'package:fleet_pulse_mobile/models/models.dart';
import 'package:fleet_pulse_mobile/services/auth/driver_api.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class FleetStanding {
  FleetStanding(this._api);

  static const String _pendingApproval = 'pending_approval';

  final DriverApi _api;

  Future<Result<DriverProfile>> check(String accessToken) async {
    try {
      final DriverProfileEnvelope envelope = await _api.me(
        'Bearer $accessToken',
      );

      return new Ok<DriverProfile>(envelope.data);
    } on DioException catch (e) {
      return new Err<DriverProfile>(_refusal(e.response));
    } on Object {
      return const Err<DriverProfile>(NetworkFailure());
    }
  }

  Failure _refusal(Response<dynamic>? response) {
    final Object? body = response?.data;
    final Object? error = body is Map<String, dynamic> ? body['error'] : null;

    AppLogger.debug('fleet standing: HTTP ${response?.statusCode} $error');

    return switch (response?.statusCode) {
      null => const NetworkFailure(),
      HttpStatus.forbidden when error == _pendingApproval =>
        const PendingApprovalFailure(),
      HttpStatus.notFound => const RegistrationIncompleteFailure(),
      HttpStatus.unauthorized || HttpStatus.forbidden => const AuthFailure(
        'The fleet refused this session. Sign in again.',
      ),
      _ => const ServiceUnavailableFailure(
        'The fleet could not be reached. Try again shortly.',
      ),
    };
  }
}
