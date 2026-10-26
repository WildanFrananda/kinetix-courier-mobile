class ClientProofUnavailableException implements Exception {
  const ClientProofUnavailableException(this.cause);

  final Object cause;

  @override
  String toString() => 'ClientProofUnavailableException: $cause';
}
