import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:fleet_pulse_mobile/config/app_config.dart';
import 'package:fleet_pulse_mobile/core/app_logger.dart';
import 'package:fleet_pulse_mobile/models/driver_session.dart';
import 'package:fleet_pulse_mobile/models/enums.dart';
import 'package:fleet_pulse_mobile/models/ids.dart';
import 'package:fleet_pulse_mobile/models/telemetry_ping.dart';
import 'package:fleet_pulse_mobile/services/channel/channel_event.dart';
import 'package:fleet_pulse_mobile/services/channel/channel_exception.dart';
import 'package:fleet_pulse_mobile/services/channel/channel_reply.dart';
import 'package:fleet_pulse_mobile/services/channel/channel_socket.dart';
import 'package:fleet_pulse_mobile/services/channel/handshake_refused_exception.dart';
import 'package:fleet_pulse_mobile/services/channel/join_refused_exception.dart';
import 'package:fleet_pulse_mobile/services/channel/push_timeout_exception.dart';
import 'package:fleet_pulse_mobile/services/channel/ws_channel_socket.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:injectable/injectable.dart';

typedef SocketConnector =
    ChannelSocket Function(Uri uri, Iterable<String> protocols);

@lazySingleton
class ChannelClient {
  ChannelClient() : _connect = WsChannelSocket.connect;

  @visibleForTesting
  ChannelClient.withConnector(this._connect);

  static const Duration heartbeatInterval = Duration(seconds: 30);
  static const Duration heartbeatTimeout = Duration(seconds: 10);
  static const Duration pushTimeout = Duration(seconds: 5);
  static const Duration joinTimeout = Duration(seconds: 10);

  static const String _tokenProtocolPrefix = 'base64url.bearer.phx.';
  static const String _notApprovedReason = 'pending_approval';
  static const Set<String> _refusingJoinReasons = <String>{
    'forbidden',
    'not_found',
    'invalid_topic',
    'unknown_topic',
  };

  final SocketConnector _connect;

  final StreamController<ChannelEvent> _events =
      new StreamController<ChannelEvent>.broadcast();
  final StreamController<ConnectionStatus> _statusCtrl =
      new StreamController<ConnectionStatus>.broadcast();
  final StreamController<void> _refusedCtrl =
      new StreamController<void>.broadcast();
  final StreamController<void> _notApprovedCtrl =
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
  String? _joinStatus;
  int _backoffAttempt = 0;
  bool _probing = false;
  ConnectionStatus _status = ConnectionStatus.disconnected;

  Stream<ChannelEvent> get events => _events.stream;
  Stream<ConnectionStatus> get statusStream => _statusCtrl.stream;
  Stream<void> get refused => _refusedCtrl.stream;
  Stream<void> get notApproved => _notApprovedCtrl.stream;
  ConnectionStatus get status => _status;
  String? get joinStatus => _joinStatus;
  DriverId? get driverId => _session?.driverId;

  String get _topic => 'driver:${_session?.driverId?.value}';

  @visibleForTesting
  static Uri socketUri(String wsBase) => Uri.parse(wsBase).replace(
    path: AppConfig.driverSocketPath,
    queryParameters: <String, String>{'vsn': AppConfig.socketProtocolVersion},
  );

  @visibleForTesting
  static List<String> protocolsFor(String token) {
    final String encoded = base64Encode(utf8.encode(token)).replaceAll('=', '');

    return <String>['phoenix', '$_tokenProtocolPrefix$encoded'];
  }

  Future<void> connect(DriverSession session, {String? wsBase}) async {
    _reconnectTimer?.cancel();
    await _teardownSocket();

    _session = session;
    _wsBase = wsBase ?? _wsBase;
    _backoffAttempt = 0;
    await _open();
  }

  Future<void> disconnect() async {
    _session = null;
    _joinStatus = null;
    _reconnectTimer?.cancel();
    await _teardownSocket();
    _setStatus(ConnectionStatus.disconnected);
  }

  Future<ChannelReply> ping(TelemetryPing p) => push('ping', _position(p));

  Future<ChannelReply> pingBatch(DriverId owner, List<TelemetryPing> pings) {
    if (_session?.driverId != owner) {
      return Future<ChannelReply>.error(
        const ChannelException('the socket belongs to another courier'),
      );
    }

    return push('ping_batch', <String, dynamic>{
      'pings': <Map<String, dynamic>>[
        for (final TelemetryPing p in pings) _position(p),
      ],
    });
  }

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

    if (socket == null ||
        _session == null ||
        _status != ConnectionStatus.connected) {
      return Future<ChannelReply>.error(
        const ChannelException('not connected'),
      );
    }

    final String ref = (++_ref).toString();
    final Completer<ChannelReply> completer = new Completer<ChannelReply>();

    _pending[ref] = completer;

    socket.add(jsonEncode(<dynamic>[_joinRef, ref, _topic, event, payload]));

    return completer.future.timeout(
      pushTimeout,
      onTimeout: () {
        _pending.remove(ref);
        _probe();
        throw new PushTimeoutException(event);
      },
    );
  }

  Map<String, dynamic> _position(TelemetryPing p) => <String, dynamic>{
    'latitude': p.latitude,
    'longitude': p.longitude,
    'recorded_at': p.recordedAt.toUtc().toIso8601String(),
    'speed_kmh': ?p.speedKmh,
    'bearing_deg': ?p.bearingDeg,
  };

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
    final DriverSession? session = _session;

    if (session == null) {
      return;
    }

    final DriverId? driver = session.driverId;

    if (driver == null) {
      AppLogger.debug('no driver is known for this session yet');
      _refuse(_notApprovedCtrl);

      return;
    }

    _setStatus(ConnectionStatus.connecting);

    try {
      final ChannelSocket socket = _connect(
        socketUri(_wsBase),
        protocolsFor(session.token),
      );

      await socket.ready;

      if (!identical(_session, session)) {
        await socket.close();

        return;
      }

      _socket = socket;
      _sub = socket.stream.listen(
        _onMessage,
        onDone: _onClosed,
        onError: (Object _, _) => _onClosed(),
        cancelOnError: true,
      );
      await _join(driver);
      _backoffAttempt = 0;
      _setStatus(ConnectionStatus.connected);
      _startHeartbeat();
    } on HandshakeRefusedException catch (e) {
      AppLogger.debug('socket upgrade answered ${e.statusCode}');
      await _teardownSocket();

      if (e.isRefusal) {
        _refuse(_refusedCtrl);
      } else {
        _scheduleReconnect();
      }
    } on JoinRefusedException catch (e) {
      AppLogger.debug('join refused: ${e.reason}');
      await _teardownSocket();

      if (e.reason == _notApprovedReason) {
        _refuse(_notApprovedCtrl);
      } else if (_refusingJoinReasons.contains(e.reason)) {
        _refuse(_refusedCtrl);
      } else {
        _scheduleReconnect();
      }
    } on Object catch (e) {
      AppLogger.debug('socket unavailable: $e');
      await _teardownSocket();
      _scheduleReconnect();
    }
  }

  Future<void> _join(DriverId driver) async {
    final String joinRef = (++_ref).toString();
    final Completer<ChannelReply> completer = new Completer<ChannelReply>();

    _joinRef = joinRef;
    _pending[joinRef] = completer;

    _socket!.add(
      jsonEncode(<dynamic>[
        joinRef,
        joinRef,
        'driver:${driver.value}',
        'phx_join',
        <String, dynamic>{},
      ]),
    );

    final ChannelReply reply = await completer.future.timeout(joinTimeout);

    if (!reply.isOk) {
      throw new JoinRefusedException(reply.reason ?? reply.status);
    }

    final Object? status = reply.response['status'];
    _joinStatus = status is String ? status : null;
  }

  void _refuse(StreamController<void> signal) {
    _session = null;
    _joinStatus = null;
    _setStatus(ConnectionStatus.disconnected);

    if (!signal.isClosed) {
      signal.add(null);
    }
  }

  void _onMessage(dynamic raw) {
    final List<dynamic> frame;
    final String? ref;
    final String event;
    final Map<String, dynamic> payload;

    try {
      frame = jsonDecode(raw as String) as List<dynamic>;
      ref = frame[1] as String?;
      event = frame[3] as String;
      payload = (frame[4] as Map<dynamic, dynamic>).cast<String, dynamic>();
    } on Object catch (e) {
      AppLogger.error('dropped an unreadable frame', error: e);

      return;
    }

    if (event == 'phx_reply') {
      final Completer<ChannelReply>? completer = ref == null
          ? null
          : _pending.remove(ref);
      final Object? status = payload['status'];
      final Object? response = payload['response'];

      completer?.complete(
        new ChannelReply(
          status is String ? status : 'error',
          response is Map<dynamic, dynamic>
              ? response.cast<String, dynamic>()
              : <String, dynamic>{},
        ),
      );

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
    _heartbeatTimer = new Timer.periodic(heartbeatInterval, (_) => _probe());
  }

  void _probe() {
    final ChannelSocket? socket = _socket;

    if (socket == null || _probing) {
      return;
    }

    final String ref = (++_ref).toString();
    final Completer<ChannelReply> completer = new Completer<ChannelReply>();

    _probing = true;
    _pending[ref] = completer;
    socket.add(
      jsonEncode(<dynamic>[
        null,
        ref,
        'phoenix',
        'heartbeat',
        <String, dynamic>{},
      ]),
    );

    unawaited(
      completer.future
          .timeout(heartbeatTimeout)
          .then<void>(
            (ChannelReply _) {
              _probing = false;
            },
            onError: (Object e) {
              _probing = false;
              _pending.remove(ref);

              if (identical(_socket, socket)) {
                AppLogger.debug('heartbeat unanswered, reconnecting: $e');
                _scheduleReconnect();
              }
            },
          ),
    );
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
    _reconnectTimer = new Timer(
      new Duration(milliseconds: ms),
      () => unawaited(_open()),
    );
  }

  Future<void> _teardownSocket() async {
    _heartbeatTimer?.cancel();
    _probing = false;

    final ChannelSocket? socket = _socket;

    _socket = null;
    _joinRef = null;

    for (final Completer<ChannelReply> c in _pending.values) {
      if (!c.isCompleted) {
        c.completeError(const ChannelException('socket closed'));
      }
    }

    _pending.clear();
    await _sub?.cancel();
    _sub = null;
    await socket?.close();
  }

  void _setStatus(ConnectionStatus s) {
    if (_statusCtrl.isClosed) {
      return;
    }

    _status = s;
    AppLogger.debug('connection: ${s.name}');
    _statusCtrl.add(s);
  }

  @disposeMethod
  Future<void> dispose() async {
    _session = null;
    _reconnectTimer?.cancel();
    await _teardownSocket();
    await _events.close();
    await _statusCtrl.close();
    await _refusedCtrl.close();
    await _notApprovedCtrl.close();
  }
}
