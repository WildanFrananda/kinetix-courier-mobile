class HolderRuntimeException implements Exception {
  const HolderRuntimeException(this.message);

  final String message;

  @override
  String toString() => 'HolderRuntimeException: $message';
}
