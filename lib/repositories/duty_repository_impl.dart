import 'dart:async';
import 'dart:math';

import 'package:clock/clock.dart';
import 'package:fleet_pulse_mobile/core/core.dart';
import 'package:fleet_pulse_mobile/models/models.dart';
import 'package:fleet_pulse_mobile/repositories/duty_repository.dart';
import 'package:fleet_pulse_mobile/services/channel/channel_client.dart';
import 'package:fleet_pulse_mobile/services/channel/channel_reply.dart';
import 'package:fleet_pulse_mobile/services/location/location_service.dart';
import 'package:fleet_pulse_mobile/services/offline/offline_position_store.dart';
import 'package:geolocator/geolocator.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: DutyRepository)
class DutyRepositoryImpl implements DutyRepository {
  DutyRepositoryImpl(this._location, this._channel, this._offline) {
    _connectionSub = _channel.statusStream.listen(_onConnection);
  }

  static const Duration cadence = Duration(seconds: 4);
  static const double minMeters = 5;
  static const Duration rateLimitPause = Duration(seconds: 10);
  static const int batchSize = 100;
  static const Duration batchSpacing = Duration(milliseconds: 2500);
  static const Duration batchRateLimitPause = Duration(seconds: 60);
  static const Duration batchRetryFirst = Duration(seconds: 5);
  static const Duration batchRetryMax = Duration(minutes: 5);
  static const Duration offlineMaxAge = Duration(hours: 24);
  static const int _maxBackoffDoublings = 6;
  static const String _clockAhead = 'ahead_of_server_clock';

  final LocationService _location;
  final ChannelClient _channel;
  final OfflinePositionStore _offline;

  final StreamController<DriverAvailability> _availabilityCtrl =
      new StreamController<DriverAvailability>.broadcast();
  final StreamController<TelemetryPing> _sentCtrl =
      new StreamController<TelemetryPing>.broadcast();
  final StreamController<Failure> _problemsCtrl =
      new StreamController<Failure>.broadcast();

  StreamSubscription<ConnectionStatus>? _connectionSub;
  StreamSubscription<Position>? _positionSub;
  Timer? _timer;
  Timer? _flushTimer;
  Position? _latest;
  Position? _lastRecorded;
  DateTime? _pausedUntil;
  DriverId? _owner;
  bool _onDuty = false;
  bool _declaredOnDuty = false;
  bool _declaring = false;
  bool _announcePending = false;
  bool _sending = false;
  bool _batchInFlight = false;
  int _flushFailures = 0;

  @override
  bool get onDuty => _onDuty;

  @override
  Stream<DriverAvailability> get availability => _availabilityCtrl.stream;

  @override
  Stream<TelemetryPing> get sent => _sentCtrl.stream;

  @override
  Stream<Failure> get problems => _problemsCtrl.stream;

  @override
  Future<void> openAppSettings() => _location.openAppSettings();

  @override
  Future<Result<DriverAvailability>> goOnDuty() async {
    if (_onDuty) {
      return _declareOnDuty();
    }

    final DriverId? owner = _channel.driverId;

    if (owner == null) {
      return const Err<DriverAvailability>(NetworkFailure());
    }

    final LocationPermissionStatus permission = await _location
        .ensurePermission(background: true);

    if (permission != LocationPermissionStatus.granted) {
      return new Err<DriverAvailability>(
        new PermissionFailure(_permissionMessage(permission)),
      );
    }

    await _location.requestNotificationPermission();
    _owner = owner;
    _startTracking();
    _onDuty = true;

    final Result<DriverAvailability> declared = await _declareOnDuty();

    if (declared case Err<DriverAvailability>(
      :final Failure failure,
    ) when failure is ChannelFailure) {
      _onDuty = false;
      _stopTracking();
    }

    return declared;
  }

  @override
  Future<Result<DriverAvailability>> goOffDuty() async {
    _onDuty = false;
    _stopTracking();

    if (_channel.status != ConnectionStatus.connected) {
      _emit(_availabilityCtrl, DriverAvailability.offline);

      return const Ok<DriverAvailability>(DriverAvailability.offline);
    }

    return _declare('offline');
  }

  void _onConnection(ConnectionStatus status) {
    if (status != ConnectionStatus.connected) {
      _declaredOnDuty = false;
      _flushTimer?.cancel();
      _flushTimer = null;

      return;
    }

    if (_onDuty) {
      unawaited(_reannounce());

      return;
    }

    unawaited(_settleOffDuty());
  }

  Future<void> _settleOffDuty() async {
    final String? joined = _channel.joinStatus;

    if (joined != null && joined != DriverAvailability.offline.name) {
      await _declare('offline');
    }

    _startFlush();
  }

  Future<void> _reannounce() async {
    if (_declaring) {
      return;
    }

    final Result<DriverAvailability> declared = await _declareOnDuty();

    if (declared case Err<DriverAvailability>(:final Failure failure)) {
      _emit(_problemsCtrl, failure);
    }
  }

  Future<Result<DriverAvailability>> _declareOnDuty() async {
    _declaring = true;

    final Result<DriverAvailability> declared = await _declare('online');

    _declaring = false;

    if (declared is Ok<DriverAvailability> && _onDuty) {
      _declaredOnDuty = true;
      _announce();
    }

    return declared;
  }

  Future<Result<DriverAvailability>> _declare(String status) async {
    final ChannelReply reply;

    try {
      reply = await _channel.setStatus(status);
    } on Object {
      return const Err<DriverAvailability>(NetworkFailure());
    }

    if (!reply.isOk) {
      return new Err<DriverAvailability>(failureFromReason(reply.reason));
    }

    final DriverAvailability? decided = DriverAvailability.fromWire(
      reply.response['status'],
    );

    if (decided == null) {
      return const Err<DriverAvailability>(ChannelFailure('unexpected_status'));
    }

    _emit(_availabilityCtrl, decided);

    return new Ok<DriverAvailability>(decided);
  }

  void _announce() {
    final Position? position = _latest;

    if (position == null) {
      _announcePending = true;

      return;
    }

    unawaited(_send(position));
  }

  void _startTracking() {
    _positionSub = _location.positions().listen(
      _onPosition,
      onError: (Object e) => _emit(
        _problemsCtrl,
        const PermissionFailure('location is not available'),
      ),
    );
    _timer = new Timer.periodic(cadence, (_) => unawaited(_tick()));
  }

  void _stopTracking() {
    _timer?.cancel();
    unawaited(_positionSub?.cancel());

    _timer = null;
    _positionSub = null;
    _latest = null;
    _lastRecorded = null;
    _pausedUntil = null;
    _owner = null;
    _declaredOnDuty = false;
    _announcePending = false;
  }

  void _onPosition(Position position) {
    _latest = position;

    if (_announcePending && _declaredOnDuty) {
      _announcePending = false;
      unawaited(_send(position));
    }
  }

  Future<void> _tick() async {
    if (!_onDuty) {
      return;
    }

    if (_joined && !_declaredOnDuty) {
      await _reannounce();
    }

    _endPauseIfOver();

    final Position? position = _latest;

    if (position == null || !_movedSinceRecorded(position)) {
      return;
    }

    if (!_joined || !_declaredOnDuty || _pausedUntil != null) {
      await _queue(position);

      return;
    }

    await _send(position);
  }

  void _endPauseIfOver() {
    final DateTime? pausedUntil = _pausedUntil;

    if (pausedUntil == null || clock.now().isBefore(pausedUntil)) {
      return;
    }

    _pausedUntil = null;
    _lastRecorded = null;
  }

  bool get _joined => _channel.status == ConnectionStatus.connected;

  bool _movedSinceRecorded(Position position) {
    final Position? last = _lastRecorded;

    return last == null ||
        Geolocator.distanceBetween(
              last.latitude,
              last.longitude,
              position.latitude,
              position.longitude,
            ) >=
            minMeters;
  }

  Future<void> _send(Position position) async {
    if (_sending) {
      return;
    }

    _sending = true;

    final TelemetryPing ping = _pingOf(position);

    try {
      final ChannelReply reply = await _channel.ping(ping);

      if (reply.isOk) {
        _lastRecorded = position;
        _emit(_sentCtrl, ping);
        _startFlush();
      } else {
        _refused(reply.reason, position);
      }
    } on Object catch (e) {
      AppLogger.debug('ping not delivered, kept for later: $e');
      await _queue(position);
    } finally {
      _sending = false;
    }
  }

  Future<void> _queue(Position position) async {
    _lastRecorded = position;

    final DriverId? owner = _owner;

    if (owner == null) {
      AppLogger.debug('a position with no courier on duty was not kept');

      return;
    }

    try {
      await _offline.add(owner, _pingOf(position));
    } on Object catch (e) {
      AppLogger.error(
        'a position recorded offline could not be kept',
        error: e,
      );
    }
  }

  void _startFlush() {
    if (_batchInFlight || (_flushTimer?.isActive ?? false) || !_joined) {
      return;
    }

    unawaited(_flushNext());
  }

  Future<void> _flushNext() async {
    _flushTimer = null;

    if (!_joined) {
      return;
    }

    _batchInFlight = true;

    final Duration? next = await _sendBatch();

    _batchInFlight = false;

    if (next != null && _joined) {
      _flushTimer = new Timer(next, () => unawaited(_flushNext()));
    }
  }

  Future<Duration?> _sendBatch() async {
    final DriverId? driver = _channel.driverId;

    if (driver == null) {
      return null;
    }

    final List<TelemetryPing> batch;

    try {
      await _offline.discardRecordedBefore(
        clock.now().toUtc().subtract(offlineMaxAge),
      );
      batch = await _offline.oldest(driver, batchSize);
    } on Object catch (e) {
      AppLogger.error('the offline positions could not be read', error: e);

      return null;
    }

    if (batch.isEmpty) {
      _flushFailures = 0;

      return null;
    }

    final ChannelReply reply;

    try {
      reply = await _channel.pingBatch(driver, batch);
    } on Object catch (e) {
      AppLogger.debug('offline positions not delivered: $e');

      return _batchBackoff();
    }

    if (!reply.isOk) {
      AppLogger.debug('offline positions not settled: ${reply.reason}');

      return reply.reason == 'rate_limited'
          ? batchRateLimitPause
          : _batchBackoff();
    }

    try {
      await _offline.remove(driver, batch);
    } on Object catch (e) {
      AppLogger.error(
        'settled offline positions could not be removed',
        error: e,
      );
    }

    _reportRefused(reply);
    _flushFailures = 0;

    return batchSpacing;
  }

  void _reportRefused(ChannelReply reply) {
    final Object? refused = reply.response['refused'];

    if (refused is! List<dynamic>) {
      return;
    }

    final Map<String, int> reasons = <String, int>{};

    for (final Object? entry in refused) {
      final Object? reason = entry is Map<dynamic, dynamic>
          ? entry['reason']
          : null;
      final String named = reason is String ? reason : 'unknown';

      reasons[named] = (reasons[named] ?? 0) + 1;
    }

    if (reasons.isEmpty) {
      return;
    }

    AppLogger.error('matching refused offline positions for good: $reasons');

    if (reasons.containsKey(_clockAhead)) {
      _emit(_problemsCtrl, const ChannelFailure(_clockAhead));
    }
  }

  Duration _batchBackoff() {
    final Duration delay =
        batchRetryFirst *
        pow(2, min(_flushFailures, _maxBackoffDoublings)).toInt();

    _flushFailures++;

    return delay > batchRetryMax ? batchRetryMax : delay;
  }

  void _refused(String? reason, Position position) {
    AppLogger.debug('ping refused: $reason');

    switch (reason) {
      case 'rate_limited':
        _pausedUntil = clock.now().add(rateLimitPause);
      case 'invalid_telemetry':
        _lastRecorded = position;
        _emit(_problemsCtrl, const ChannelFailure('invalid_telemetry'));
      default:
        _emit(_problemsCtrl, failureFromReason(reason));
    }
  }

  TelemetryPing _pingOf(Position position) {
    return new TelemetryPing(
      latitude: position.latitude,
      longitude: position.longitude,
      recordedAt: position.timestamp.toUtc(),
      speedKmh: position.speed >= 0 ? position.speed * 3.6 : null,
      bearingDeg: position.heading >= 0 && position.heading < 360
          ? position.heading
          : null,
    );
  }

  void _emit<T>(StreamController<T> controller, T value) {
    if (!controller.isClosed) {
      controller.add(value);
    }
  }

  String _permissionMessage(LocationPermissionStatus status) {
    return switch (status) {
      LocationPermissionStatus.serviceDisabled => 'location services disabled',
      LocationPermissionStatus.deniedForever =>
        'location permission permanently denied',
      _ => 'location permission denied',
    };
  }

  @override
  @disposeMethod
  Future<void> dispose() async {
    _stopTracking();
    _flushTimer?.cancel();
    await _connectionSub?.cancel();
    await _availabilityCtrl.close();
    await _sentCtrl.close();
    await _problemsCtrl.close();
  }
}
