import 'dart:async';
import 'dart:math';

import 'package:fleet_pulse_mobile/config/app_config.dart';
import 'package:fleet_pulse_mobile/core/core.dart';
import 'package:fleet_pulse_mobile/models/models.dart';
import 'package:fleet_pulse_mobile/repositories/connection_repository.dart';
import 'package:fleet_pulse_mobile/services/auth/fleet_standing.dart';
import 'package:fleet_pulse_mobile/services/auth/session_renewer.dart';
import 'package:fleet_pulse_mobile/services/auth/token_store.dart';
import 'package:fleet_pulse_mobile/services/channel/channel_client.dart';
import 'package:fleet_pulse_mobile/state/session_end.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: ConnectionRepository)
class ConnectionRepositoryImpl implements ConnectionRepository {
  ConnectionRepositoryImpl(
    this._channel,
    this._renewer,
    this._fleet,
    this._store,
  ) {
    _refusedSub = _channel.refused.listen((_) => unawaited(_onRefused()));
    _notApprovedSub = _channel.notApproved.listen(
      (_) => _end(const SessionNotApproved()),
    );
    _statusSub = _channel.statusStream.listen(_onStatus);
  }

  static const int maxRecoveryDelaySeconds = 30;

  final ChannelClient _channel;
  final SessionRenewer _renewer;
  final FleetStanding _fleet;
  final TokenStore _store;

  final StreamController<SessionEnd> _ended =
      new StreamController<SessionEnd>.broadcast();

  StreamSubscription<void>? _refusedSub;
  StreamSubscription<void>? _notApprovedSub;
  StreamSubscription<ConnectionStatus>? _statusSub;
  Timer? _recoveryTimer;
  Future<void> Function()? _pendingRecovery;
  DriverSession? _session;
  int _recoveryAttempt = 0;
  bool _wanted = false;
  bool _renewedSinceConnected = false;

  @override
  Stream<ConnectionStatus> get statusStream => _channel.statusStream;

  @override
  Stream<SessionEnd> get sessionEnded => _ended.stream;

  @override
  void onResume() {
    final Future<void> Function()? pending = _pendingRecovery;

    if (pending != null && (_recoveryTimer?.isActive ?? false)) {
      _cancelRecovery();
      unawaited(pending());

      return;
    }

    _channel.reconnectNow();
  }

  @override
  Future<void> connect(DriverSession session) {
    _wanted = true;
    _session = session;
    _renewedSinceConnected = false;

    return _channel.connect(session, wsBase: AppConfig.wsBase);
  }

  @override
  Future<void> disconnect() {
    _wanted = false;
    _cancelRecovery();
    _recoveryAttempt = 0;

    return _channel.disconnect();
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
      await _explainRefusal();

      return;
    }

    await _renew();
  }

  Future<void> _renew() async {
    if (!_wanted) {
      return;
    }

    final Result<DriverSession> renewed = await _renewer.renew();

    if (!_wanted) {
      return;
    }

    switch (renewed) {
      case Ok<DriverSession>(:final DriverSession value):
        _session = value;
        _renewedSinceConnected = true;
        await _channel.connect(value, wsBase: AppConfig.wsBase);
      case Err<DriverSession>(:final Failure failure)
          when failure is AuthFailure:
        _end(const SessionSignedOut());
      case Err<DriverSession>(:final Failure failure)
          when failure is AppUpdateRequiredFailure:
        _end(const SessionUpdateRequired());
      case Err<DriverSession>():
        _scheduleRecovery(_renew);
    }
  }

  Future<void> _explainRefusal() async {
    final DriverSession? session = _session;

    if (session == null) {
      _end(const SessionSignedOut());

      return;
    }

    final Result<DriverProfile> standing = await _fleet.check(session.token);

    if (!_wanted) {
      return;
    }

    switch (standing) {
      case Ok<DriverProfile>(:final DriverProfile value)
          when value.id != session.driverId:
        await _rebind(session, value.id);
      case Err<DriverProfile>(:final Failure failure)
          when failure is PendingApprovalFailure:
        _end(const SessionNotApproved());
      case Err<DriverProfile>(:final Failure failure)
          when failure is AuthFailure ||
              failure is RegistrationIncompleteFailure:
        _end(const SessionSignedOut());
      case Ok<DriverProfile>() || Err<DriverProfile>():
        _scheduleRecovery(_reconnect);
    }
  }

  Future<void> _rebind(DriverSession session, DriverId driverId) async {
    AppLogger.debug('the fleet names this courier driver ${driverId.value}');
    await _store.rebind(driverId);

    if (!_wanted) {
      return;
    }

    _session = session.copyWith(driverId: driverId);
    await _reconnect();
  }

  Future<void> _reconnect() async {
    final DriverSession? session = _session;

    if (!_wanted || session == null) {
      return;
    }

    await _channel.connect(session, wsBase: AppConfig.wsBase);
  }

  void _end(SessionEnd end) {
    if (!_wanted || _ended.isClosed) {
      return;
    }

    _wanted = false;
    _cancelRecovery();
    _ended.add(end);
  }

  void _scheduleRecovery(Future<void> Function() action) {
    final int seconds = min(
      maxRecoveryDelaySeconds,
      pow(2, _recoveryAttempt).toInt(),
    );

    AppLogger.debug(
      'session recovery in ${seconds}s (attempt ${_recoveryAttempt + 1})',
    );

    _recoveryAttempt++;
    _recoveryTimer?.cancel();
    _pendingRecovery = action;
    _recoveryTimer = new Timer(new Duration(seconds: seconds), () {
      _pendingRecovery = null;
      unawaited(action());
    });
  }

  void _cancelRecovery() {
    _recoveryTimer?.cancel();
    _pendingRecovery = null;
  }

  @override
  @disposeMethod
  Future<void> dispose() async {
    _wanted = false;
    _cancelRecovery();
    await _refusedSub?.cancel();
    await _notApprovedSub?.cancel();
    await _statusSub?.cancel();
    await _ended.close();
  }
}
