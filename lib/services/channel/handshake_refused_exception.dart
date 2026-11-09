import 'dart:io' show HttpStatus;

class HandshakeRefusedException implements Exception {
  const HandshakeRefusedException(this.statusCode);

  final int statusCode;

  bool get isRefusal =>
      statusCode == HttpStatus.unauthorized ||
      statusCode == HttpStatus.forbidden;

  @override
  String toString() =>
      'HandshakeRefusedException: the upgrade was answered $statusCode';
}
