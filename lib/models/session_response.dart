import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kinetix_courier/models/authenticated_account.dart';

part 'session_response.freezed.dart';
part 'session_response.g.dart';

@freezed
abstract class SessionResponse with _$SessionResponse {
  const factory SessionResponse({
    required String accessToken,
    required String refreshToken,
    required int expiresIn,
    required String tokenType,
    required AuthenticatedAccount user,
  }) = _SessionResponse;

  factory SessionResponse.fromJson(Map<String, dynamic> json) =>
      _$SessionResponseFromJson(json);
}
