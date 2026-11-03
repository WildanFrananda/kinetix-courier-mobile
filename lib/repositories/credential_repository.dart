import 'package:fleet_pulse_mobile/core/core.dart';
import 'package:fleet_pulse_mobile/models/models.dart';

abstract interface class CredentialRepository {
  Future<Result<CourierCredential?>> current();

  Future<Result<CourierCredential>> request();

  Future<Result<Unit>> refreshPublicState({required bool force});

  Future<Result<Unit>> prepareHolder();

  Future<Result<PresentationOffer>> offerFor(String scanned);

  Future<Result<PresentedAnswer>> present(PresentationOffer offer);
}
