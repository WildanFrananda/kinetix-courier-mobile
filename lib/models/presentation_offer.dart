import 'package:freezed_annotation/freezed_annotation.dart';

part 'presentation_offer.freezed.dart';

@freezed
abstract class PresentationOffer with _$PresentationOffer {
  const factory PresentationOffer({
    required String contractAddress,
    required String predicateId,
    required String challenge,
    required Uri answerUrl,
    required String label,
    required int deliveries,
    required int ratingHundredths,
    required int daysActive,
    required String issuedSince,
  }) = _PresentationOffer;
}
