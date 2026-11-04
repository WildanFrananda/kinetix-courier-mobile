import 'package:kinetix_courier/core/core.dart';
import 'package:kinetix_courier/models/models.dart';

sealed class CredentialUiState {
  const CredentialUiState();
}

class CredentialLoading extends CredentialUiState {
  const CredentialLoading();
}

class CredentialAbsent extends CredentialUiState {
  const CredentialAbsent({this.requesting = false, this.error});

  final bool requesting;
  final Failure? error;
}

class CredentialShowing extends CredentialUiState {
  const CredentialShowing(
    this.credential, {
    this.requesting = false,
    this.error,
  });

  final CourierCredential credential;
  final bool requesting;
  final Failure? error;
}
