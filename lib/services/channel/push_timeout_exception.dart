import 'package:kinetix_courier/services/channel/channel_exception.dart';

class PushTimeoutException extends ChannelException {
  const PushTimeoutException(String event) : super('push "$event" timed out');
}
