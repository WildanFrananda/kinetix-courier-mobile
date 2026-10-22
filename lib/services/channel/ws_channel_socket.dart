import 'dart:io' show WebSocketException;

import 'package:fleet_pulse_mobile/services/channel/channel_socket.dart';
import 'package:fleet_pulse_mobile/services/channel/handshake_refused_exception.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WsChannelSocket implements ChannelSocket {
  WsChannelSocket(this._channel);

  factory WsChannelSocket.connect(Uri uri, Iterable<String> protocols) {
    return new WsChannelSocket(
      new IOWebSocketChannel.connect(
        uri,
        protocols: protocols,
        connectTimeout: _connectTimeout,
      ),
    );
  }

  static const Duration _connectTimeout = Duration(seconds: 10);

  final WebSocketChannel _channel;

  @override
  Future<void> get ready async {
    try {
      await _channel.ready;
    } on WebSocketChannelException catch (e) {
      final Object? inner = e.inner;
      final int? status = inner is WebSocketException
          ? inner.httpStatusCode
          : null;

      if (status != null) {
        throw new HandshakeRefusedException(status);
      }

      rethrow;
    }
  }

  @override
  Stream<dynamic> get stream => _channel.stream;

  @override
  void add(String data) => _channel.sink.add(data);

  @override
  Future<void> close() => _channel.sink.close();
}
