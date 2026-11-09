import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:injectable/injectable.dart';
import 'package:kinetix_courier/services/attestation/client_proof_source.dart';

@LazySingleton(as: ClientProofSource)
class FirebaseClientProofSource implements ClientProofSource {
  @override
  Future<String?> token({required bool forceRefresh}) {
    return FirebaseAppCheck.instance.getToken(forceRefresh);
  }
}
