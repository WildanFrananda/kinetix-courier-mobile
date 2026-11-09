import 'dart:io' show HttpHeaders, HttpStatus;

import 'package:dio/dio.dart';

abstract final class IdentityError {
  static const String proofRequired = 'CLIENT_PROOF_REQUIRED';
  static const String proofInvalid = 'CLIENT_PROOF_INVALID';
  static const String proofUnavailable = 'CLIENT_PROOF_UNAVAILABLE';
  static const String clientMismatch = 'CLIENT_MISMATCH';
  static const String unknownClient = 'UNKNOWN_CLIENT';
  static const String clientRequired = 'CLIENT_REQUIRED';
  static const String signInDelayed = 'SIGN_IN_DELAYED';
  static const String wrongCodeMessage = 'That code is not valid';
  static const String exhaustedChallengeMessage =
      'This challenge allows no more attempts; sign in again';

  static String? codeOf(Response<dynamic>? response) {
    final Object? body = response?.data;
    if (body is! Map<dynamic, dynamic>) {
      return null;
    }

    final Object? code = body['error'];

    return code is String ? code : null;
  }

  static bool refusesProof(Response<dynamic>? response) {
    final String? code = codeOf(response);

    return response?.statusCode == HttpStatus.unauthorized &&
        (code == proofRequired || code == proofInvalid);
  }

  static bool mismatchedClient(Response<dynamic>? response) {
    return response?.statusCode == HttpStatus.unauthorized &&
        codeOf(response) == clientMismatch;
  }

  static bool outdatedClient(Response<dynamic>? response) {
    final String? code = codeOf(response);

    return response?.statusCode == HttpStatus.badRequest &&
        (code == unknownClient || code == clientRequired);
  }

  static bool proofUnverifiable(Response<dynamic>? response) {
    return response?.statusCode == HttpStatus.serviceUnavailable &&
        codeOf(response) == proofUnavailable;
  }

  static Duration? delayOf(Response<dynamic>? response) {
    if (response?.statusCode != HttpStatus.tooManyRequests) {
      return null;
    }

    final Object? body = response?.data;
    if (codeOf(response) == signInDelayed && body is Map<dynamic, dynamic>) {
      final Object? stated = body['retryAfterSeconds'];
      if (stated is num && stated > 0) {
        return new Duration(seconds: stated.ceil());
      }
    }

    final String? header = response
        ?.headers[HttpHeaders.retryAfterHeader]
        ?.firstOrNull
        ?.trim();
    final int? seconds = header == null ? null : int.tryParse(header);

    return seconds != null && seconds > 0
        ? new Duration(seconds: seconds)
        : null;
  }

  static bool wrongCode(Response<dynamic>? response) {
    return response?.statusCode == HttpStatus.unauthorized &&
        _messageOf(response) == wrongCodeMessage;
  }

  static bool challengeExhausted(Response<dynamic>? response) {
    return response?.statusCode == HttpStatus.unauthorized &&
        _messageOf(response) == exhaustedChallengeMessage;
  }

  static String? _messageOf(Response<dynamic>? response) {
    final Object? body = response?.data;
    if (body is! Map<dynamic, dynamic>) {
      return null;
    }

    final Object? message = body['message'];

    return message is String ? message : null;
  }
}
