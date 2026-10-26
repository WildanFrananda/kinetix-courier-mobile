import 'package:fleet_pulse_mobile/services/channel/channel_exception.dart';

class PushTimeoutException extends ChannelException {
  const PushTimeoutException(String event) : super('push "$event" timed out');
}
