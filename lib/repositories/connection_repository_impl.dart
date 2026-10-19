import 'dart:async';
import 'dart:math';

import 'package:fleet_pulse_mobile/config/app_config.dart';
import 'package:fleet_pulse_mobile/core/core.dart';
import 'package:fleet_pulse_mobile/models/driver_session.dart';
import 'package:fleet_pulse_mobile/models/enums.dart';
import 'package:fleet_pulse_mobile/models/telemetry_ping.dart';
import 'package:fleet_pulse_mobile/repositories/connection_repository.dart';
import 'package:fleet_pulse_mobile/services/auth/session_renewer.dart';
import 'package:fleet_pulse_mobile/services/channel/channel_client.dart';
import 'package:fleet_pulse_mobile/services/channel/channel_event.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: ConnectionRepository)
class ConnectionRepositoryImpl implements ConnectionRepository {
  ConnectionRepositoryImpl(this._channel, this._renewer) {
    _refusedSub = _channel.unauthorized.listen((_) => unawaited(_onRefused()));
    _statusSub = _channel.statusStream.listen(_onStatus);
  }

  static const int maxRecoveryDelaySeconds = 30;

  final ChannelClient _channel;
  final SessionRenewer _renewer;

  final StreamController<void> _expired =
      new StreamController<void>.broadcast();

  StreamSubscription<void>? _refusedSub;
  StreamSubscription<ConnectionStatus>? _statusSub;
  Timer? _recoveryTimer;
  int _recoveryAttempt = 0;
  bool _wanted = false;
  bool _renewedSinceConnected = false;

  @override
  Stream<ConnectionStatus> get statusStream => _channel.statusStream;

  @override
  Stream<void> get sessionExpired => _expired.stream;

  @override
  void onResume() {
    if (_recoveryTimer?.isActive ?? false) {
      _recoveryTimer?.cancel();
      unawaited(_recover());

      return;
    }

    _channel.reconnectNow();
  }

  @override
  Future<void> connect(DriverSession session) {
    _wanted = true;
    _renewedSinceConnected = false;

    return _channel.connect(session, wsBase: AppConfig.wsBase);
  }

  @override
  Future<void> disconnect() {
    _wanted = false;
    _recoveryTimer?.cancel();
    _recoveryAttempt = 0;

    return _channel.disconnect();
  }

  @override
  Future<Result<Unit>> sendPing(TelemetryPing ping) async {
    try {
      final ChannelReply reply = await _channel.ping(ping);

      return reply.isOk
          ? const Ok<Unit>(Unit.unit)
          : new Err<Unit>(failureFromReason(reply.reason));
    } on ChannelException {
      return const Err<Unit>(NetworkFailure());
    } on Object {
      return const Err<Unit>(NetworkFailure());
    }
  }

  @override
  Future<Result<Unit>> setStatus(String status) async {
    try {
      final ChannelReply reply = await _channel.setStatus(status);

      return reply.isOk
          ? const Ok<Unit>(Unit.unit)
          : new Err<Unit>(failureFromReason(reply.reason));
    } on ChannelException {
      return const Err<Unit>(NetworkFailure());
    } on Object {
      return const Err<Unit>(NetworkFailure());
    }
  }

  void _onStatus(ConnectionStatus status) {
    if (status == ConnectionStatus.connected) {
      _renewedSinceConnected = false;
      _recoveryAttempt = 0;
    }
  }

  Future<void> _onRefused() async {
    if (!_wanted) {
      return;
    }

    if (_renewedSinceConnected) {
      _expired.add(null);

      return;
    }

    await _recover();
  }

  Future<void> _recover() async {
    if (!_wanted) {
      return;
    }

    final Result<DriverSession> renewed = await _renewer.renew();

    if (!_wanted) {
      return;
    }

    switch (renewed) {
      case Ok<DriverSession>(:final DriverSession value):
        _renewedSinceConnected = true;
        await _channel.connect(value, wsBase: AppConfig.wsBase);
      case Err<DriverSession>(:final Failure failure)
          when failure is AuthFailure:
        _expired.add(null);
      case Err<DriverSession>():
        _scheduleRecovery();
    }
  }

  void _scheduleRecovery() {
    final int seconds = min(
      maxRecoveryDelaySeconds,
      pow(2, _recoveryAttempt).toInt(),
    );

    AppLogger.debug(
      'session renewal retry in ${seconds}s (attempt ${_recoveryAttempt + 1})',
    );

    _recoveryAttempt++;
    _recoveryTimer?.cancel();
    _recoveryTimer = new Timer(
      new Duration(seconds: seconds),
      () => unawaited(_recover()),
    );
  }

  @disposeMethod
  Future<void> dispose() async {
    _recoveryTimer?.cancel();
    await _refusedSub?.cancel();
    await _statusSub?.cancel();
    await _expired.close();
  }
}
