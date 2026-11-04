import 'package:kinetix_courier/core/core.dart';
import 'package:kinetix_courier/models/models.dart';

abstract interface class CredentialRepository {
  Future<Result<CourierCredential?>> current();

  Future<Result<CourierCredential>> request();

  Future<Result<Unit>> refreshPublicState({required bool force});

  Future<Result<Unit>> prepareHolder();

  Future<Result<PresentationOffer>> offerFor(String scanned);

  Future<Result<PresentedAnswer>> present(PresentationOffer offer);
}
