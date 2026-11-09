import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kinetix_courier/models/credential_placement.dart';
import 'package:kinetix_courier/models/credential_standing.dart';

part 'courier_credential.freezed.dart';

@freezed
abstract class CourierCredential with _$CourierCredential {
  const factory CourierCredential({
    required String id,
    required CredentialStanding standing,
    required int issueDay,
    required int deliveries,
    required int ratingHundredths,
    required int daysActive,
    required CredentialPlacement? placement,
  }) = _CourierCredential;
}
