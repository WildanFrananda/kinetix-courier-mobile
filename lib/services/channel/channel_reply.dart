class ChannelReply {
  const ChannelReply(this.status, this.response);

  final String status;
  final Map<String, dynamic> response;

  bool get isOk => status == 'ok';

  String? get reason {
    final Object? reason = response['reason'];

    return reason is String ? reason : null;
  }
}
