class ChannelEvent {
  const ChannelEvent(this.event, this.payload);

  final String event;
  final Map<String, dynamic> payload;
}
