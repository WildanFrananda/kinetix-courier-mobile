class ChannelException implements Exception {
  const ChannelException(this.message);

  final String message;

  @override
  String toString() => 'ChannelException: $message';
}
