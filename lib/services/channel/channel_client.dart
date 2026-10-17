import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:fleet_pulse_mobile/core/core.dart';
import 'package:fleet_pulse_mobile/models/driver_session.dart';
import 'package:fleet_pulse_mobile/models/enums.dart';
import 'package:fleet_pulse_mobile/models/telemetry_ping.dart';
import 'package:fleet_pulse_mobile/services/channel/channel_event.dart';
import 'package:fleet_pulse_mobile/services/channel/channel_socket.dart';
import 'package:fleet_pulse_mobile/services/channel/ws_channel_socket.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:injectable/injectable.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

typedef SocketConnector = ChannelSocket Function(Uri uri);

@lazySingleton
class ChannelClient {
  ChannelClient() : _connect = _defaultConnector;

  @visibleForTesting
  ChannelClient.withConnector(this._connect);

  static ChannelSocket _defaultConnector(Uri uri) =>
      new WsChannelSocket(WebSocketChannel.connect(uri));

  final SocketConnector _connect;

  final StreamController<ChannelEvent> _events =
      new StreamController<ChannelEvent>.broadcast();
  final StreamController<ConnectionStatus> _statusCtrl =
      new StreamController<ConnectionStatus>.broadcast();
  final StreamController<void> _authCtrl =
      new StreamController<void>.broadcast();

  final Map<String, Completer<ChannelReply>> _pending =
      <String, Completer<ChannelReply>>{};

  final Random _rng = new Random();

  ChannelSocket? _socket;
  StreamSubscription<dynamic>? _sub;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;

  DriverSession? _session;
  String _wsBase = '';
  int _ref = 0;
  String? _joinRef;
  int _backoffAttempt = 0;
  ConnectionStatus _status = ConnectionStatus.disconnected;

  Stream<ChannelEvent> get events => _events.stream;
  Stream<ConnectionStatus> get statusStream => _statusCtrl.stream;
  Stream<void> get unauthorized => _authCtrl.stream;
  ConnectionStatus get status => _status;

  String get _topic => 'driver:${_session!.driverId.value}';

  Future<void> connect(DriverSession session, {String? wsBase}) async {
    _session = session;
    _wsBase = wsBase ?? _wsBase;
    _backoffAttempt = 0;
    await _open();
  }

  Future<void> disconnect() async {
    _session = null;
    _reconnectTimer?.cancel();
    await _teardownSocket();
    _setStatus(ConnectionStatus.disconnected);
  }

  Future<ChannelReply> ping(TelemetryPing p) => push('ping', <String, dynamic>{
    'latitude': p.latitude,
    'longitude': p.longitude,
    'recorded_at': p.recordedAt.toUtc().toIso8601String(),
    if (p.speedKmh != null) 'speed_kmh': p.speedKmh,
    if (p.bearingDeg != null) 'bearing_deg': p.bearingDeg,
  });

  Future<ChannelReply> setStatus(String status) =>
      push('status', <String, dynamic>{'status': status});

  Future<ChannelReply> pickup(int orderId) =>
      push('pickup', <String, dynamic>{'order_id': orderId});

  Future<ChannelReply> podUpload(int orderId, String photoSha256) => push(
    'pod_upload',
    <String, dynamic>{'order_id': orderId, 'photo_sha256': photoSha256},
  );

  Future<ChannelReply> delivered(
    int orderId, {
    String? podPhotoUrl,
    String? podSignature,
  }) => push('delivered', <String, dynamic>{
    'order_id': orderId,
    'pod_photo_url': ?podPhotoUrl,
    'pod_signature': ?podSignature,
  });

  Future<ChannelReply> push(String event, Map<String, dynamic> payload) {
    final ChannelSocket? socket = _socket;

    if (socket == null || _session == null) {
      return Future<ChannelReply>.error(
        const ChannelException('not connected'),
      );
    }

    final String ref = (++_ref).toString();
    final Completer<ChannelReply> completer = new Completer<ChannelReply>();

    _pending[ref] = completer;

    socket.add(jsonEncode(<dynamic>[_joinRef, ref, _topic, event, payload]));

    return completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        _pending.remove(ref);
        throw new ChannelException('push "$event" timed out');
      },
    );
  }

  void reconnectNow() {
    if (_session == null ||
        _status == ConnectionStatus.connected ||
        _status == ConnectionStatus.connecting) {
      return;
    }

    _reconnectTimer?.cancel();
    _backoffAttempt = 0;
    unawaited(_open());
  }

  Future<void> _open() async {
    _setStatus(ConnectionStatus.connecting);

    try {
      final Uri uri = Uri.parse(
        '$_wsBase/driver/websocket?token=${_session!.token}&vsn=2.0.0',
      );
      final ChannelSocket socket = _connect(uri);
      await socket.ready;
      _socket = socket;
      _sub = socket.stream.listen(
        _onMessage,
        onDone: _onClosed,
        onError: (Object _, _) => _onClosed(),
        cancelOnError: true,
      );
      await _join();
      _backoffAttempt = 0;
      _setStatus(ConnectionStatus.connected);
      _startHeartbeat();
    } on UnauthorizedException {
      _session = null;
      await _teardownSocket();
      _setStatus(ConnectionStatus.disconnected);
      _authCtrl.add(null);
    } on Object catch (e) {
      await _teardownSocket();
      if (_looksUnauthorized(e)) {
        _session = null;
        _setStatus(ConnectionStatus.disconnected);
        _authCtrl.add(null);
      } else {
        _scheduleReconnect();
      }
    }
  }

  Future<void> _join() async {
    _joinRef = (++_ref).toString();
    final Completer<ChannelReply> completer = new Completer<ChannelReply>();
    _pending[_joinRef!] = completer;

    _socket!.add(
      jsonEncode(<dynamic>[
        _joinRef,
        _joinRef,
        _topic,
        'phx_join',
        <String, dynamic>{},
      ]),
    );

    final ChannelReply reply = await completer.future.timeout(
      const Duration(seconds: 10),
    );

    if (!reply.isOk) {
      final String reason = reply.reason ?? reply.status;
      if (reason == 'forbidden' || reason == 'unauthorized') {
        throw const UnauthorizedException();
      }

      throw new ChannelException('join refused: $reason');
    }
  }

  void _onMessage(dynamic raw) {
    final List<dynamic> frame = jsonDecode(raw as String) as List<dynamic>;
    final String? ref = frame[1] as String?;
    final String event = frame[3] as String;
    final Map<String, dynamic> payload = (frame[4] as Map<dynamic, dynamic>)
        .cast<String, dynamic>();

    if (event == 'phx_reply') {
      final Completer<ChannelReply>? completer = ref == null
          ? null
          : _pending.remove(ref);
      final String status = payload['status'] as String? ?? 'error';
      final Map<String, dynamic> response =
          (payload['response'] as Map<dynamic, dynamic>?)
              ?.cast<String, dynamic>() ??
          <String, dynamic>{};

      completer?.complete(new ChannelReply(status, response));

      return;
    }

    if (event == 'phx_error' || event == 'phx_close') {
      _onClosed();
      return;
    }

    _events.add(new ChannelEvent(event, payload));
  }

  void _onClosed() {
    if (_session == null) {
      return;
    }
    _scheduleReconnect();
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = new Timer.periodic(const Duration(seconds: 30), (_) {
      final ChannelSocket? socket = _socket;

      if (socket == null) {
        return;
      }

      final String ref = (++_ref).toString();

      socket.add(
        jsonEncode(<dynamic>[
          null,
          ref,
          'phoenix',
          'heartbeat',
          <String, dynamic>{},
        ]),
      );
    });
  }

  void _scheduleReconnect() {
    unawaited(_teardownSocket());

    if (_session == null) {
      return;
    }

    _setStatus(ConnectionStatus.reconnecting);

    final int base = min(30, pow(2, _backoffAttempt).toInt());
    final int ms = base * 1000 + _rng.nextInt(1000);

    AppLogger.debug('reconnect in ${ms}ms (attempt ${_backoffAttempt + 1})');

    _backoffAttempt++;
    _reconnectTimer?.cancel();
    _reconnectTimer = new Timer(Duration(milliseconds: ms), _open);
  }

  Future<void> _teardownSocket() async {
    _heartbeatTimer?.cancel();
    await _sub?.cancel();
    _sub = null;

    await _socket?.close();
    _socket = null;
    _joinRef = null;

    for (final Completer<ChannelReply> c in _pending.values) {
      if (!c.isCompleted) {
        c.completeError(const ChannelException('socket closed'));
      }
    }

    _pending.clear();
  }

  void _setStatus(ConnectionStatus s) {
    _status = s;
    AppLogger.debug('connection: ${s.name}');
    _statusCtrl.add(s);
  }

  bool _looksUnauthorized(Object e) {
    final String s = e.toString().toLowerCase();

    AppLogger.debug('auth rejected — routing to login');

    return s.contains('403') || s.contains('401') || s.contains('forbidden');
  }

  @disposeMethod
  Future<void> dispose() async {
    _reconnectTimer?.cancel();
    await _teardownSocket();
    await _events.close();
    await _statusCtrl.close();
    await _authCtrl.close();
  }
}
