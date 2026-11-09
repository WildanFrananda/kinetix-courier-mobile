import 'package:freezed_annotation/freezed_annotation.dart';

part 'delivery_proof_draft.freezed.dart';

@freezed
abstract class DeliveryProofDraft with _$DeliveryProofDraft {
  const factory DeliveryProofDraft({String? photoUrl, String? signature}) =
      _DeliveryProofDraft;
}
