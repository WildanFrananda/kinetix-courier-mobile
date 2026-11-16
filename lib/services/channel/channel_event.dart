class ChannelEvent {
  const ChannelEvent(
    this.event,
    this.payload, {
    this.eventId,
    this.orderId,
    this.sequence,
    this.occurredAt,
  });

  final String event;
  final Map<String, dynamic> payload;
  final String? eventId;
  final String? orderId;
  final int? sequence;
  final DateTime? occurredAt;
}
