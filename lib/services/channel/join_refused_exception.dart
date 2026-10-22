class JoinRefusedException implements Exception {
  const JoinRefusedException(this.reason);

  final String reason;

  @override
  String toString() => 'JoinRefusedException: $reason';
}
