abstract interface class ClientProofSource {
  Future<String?> token({required bool forceRefresh});
}
