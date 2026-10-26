import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:fleet_pulse_mobile/services/attestation/client_proof_source.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: ClientProofSource)
class FirebaseClientProofSource implements ClientProofSource {
  @override
  Future<String?> token({required bool forceRefresh}) {
    return FirebaseAppCheck.instance.getToken(forceRefresh);
  }
}
