import 'dart:async';

import 'package:fleet_pulse_mobile/core/core.dart';
import 'package:fleet_pulse_mobile/models/models.dart';
import 'package:fleet_pulse_mobile/repositories/connection_repository.dart';
import 'package:fleet_pulse_mobile/repositories/duty_repository.dart';
import 'package:fleet_pulse_mobile/repositories/order_repository.dart';
import 'package:fleet_pulse_mobile/repositories/session_repository.dart';
import 'package:fleet_pulse_mobile/routes/app_route.dart';
import 'package:fleet_pulse_mobile/routes/app_router_state.dart';
import 'package:fleet_pulse_mobile/state/state.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart' hide Order;

@injectable
class TrackingViewModel extends ChangeNotifier {
  TrackingViewModel(
    this._router,
    this._connection,
    this._orders,
    this._duty,
    this._session,
  ) {
    _connSub = _connection.statusStream.listen(_onStatus);
    _pingSub = _duty.sent.listen(_onPing);
    _availabilitySub = _duty.availability.listen(_onAvailability);
    _problemSub = _duty.problems.listen(_onProblem);
    _jobSub = _orders.watchJobs().listen(_onJob);
    _endSub = _connection.sessionEnded.listen(
      (SessionEnd end) => unawaited(_onSessionEnded(end)),
    );
    unawaited(_init());
  }

  final AppRouterState _router;
  final ConnectionRepository _connection;
  final OrderRepository _orders;
  final DutyRepository _duty;
  final SessionRepository _session;

  StreamSubscription<ConnectionStatus>? _connSub;
  StreamSubscription<TelemetryPing>? _pingSub;
  StreamSubscription<DriverAvailability>? _availabilitySub;
  StreamSubscription<Failure>? _problemSub;
  StreamSubscription<JobUpdate>? _jobSub;
  StreamSubscription<SessionEnd>? _endSub;

  TrackingState _state = const TrackingConnecting();
  ConnectionStatus _conn = ConnectionStatus.connecting;
  DriverAvailability _availability = DriverAvailability.offline;
  bool _hasJob = false;
  TelemetryPing? _lastPing;
  String? _message;
  bool _permissionBlocked = false;
  int? _showOrderId;

  TrackingState get state => _state;

  Future<void> openSettings() => _duty.openAppSettings();

  Future<void> _init() async {
    final DriverSession? s = await _session.currentSession();

    if (s == null) {
      _router.replaceAll(const LoginRoute());

      return;
    }

    await _connection.connect(s);
  }

  Future<void> toggleDuty() async {
    final Result<DriverAvailability> res = _duty.onDuty
        ? await _duty.goOffDuty()
        : await _duty.goOnDuty();

    switch (res) {
      case Ok<DriverAvailability>(:final DriverAvailability value):
        _availability = value;
        _message = null;
        _permissionBlocked = false;
      case Err<DriverAvailability>(:final Failure failure):
        _message = failure.message;
        _permissionBlocked = failure is PermissionFailure;
    }

    _recompute();
  }

  Future<void> logout() async {
    await _duty.goOffDuty();
    await _connection.disconnect();
    await _session.logout();
    _router.replaceAll(const LoginRoute());
  }

  Future<void> _onSessionEnded(SessionEnd end) async {
    await _duty.goOffDuty();
    await _connection.disconnect();

    switch (end) {
      case SessionSignedOut():
        await _session.logout();
        _router.replaceAll(const LoginRoute());
      case SessionNotApproved():
        _router.replaceAll(const PendingApprovalRoute());
      case SessionUpdateRequired():
        _router.replaceAll(const UpdateRequiredRoute());
    }
  }

  void _onStatus(ConnectionStatus s) {
    _conn = s;
    _recompute();
  }

  void _onPing(TelemetryPing p) {
    _lastPing = p;
    _recompute();
  }

  void _onAvailability(DriverAvailability availability) {
    _availability = availability;
    _recompute();
  }

  void _onProblem(Failure failure) {
    _message = failure.message;
    _recompute();
  }

  void _onJob(JobUpdate update) {
    switch (update) {
      case JobActive(:final Order order):
        _hasJob =
            order.status == OrderStatus.assigned ||
            order.status == OrderStatus.pickedUp;

        if (_hasJob && order.id.value != _showOrderId) {
          _showOrderId = order.id.value;
          _router.push(new OrderRoute(order: order));
        }
      case JobNone():
        _hasJob = false;
        _showOrderId = null;
      case JobCancelled(:final OrderId id) || JobUnassigned(:final OrderId id):
        if (id.value == _showOrderId) {
          _hasJob = false;
          _showOrderId = null;
        }
    }

    _recompute();
  }

  DriverAvailability get _shownAvailability {
    if (!_duty.onDuty) {
      return DriverAvailability.offline;
    }

    return _hasJob ? DriverAvailability.busy : _availability;
  }

  void _recompute() {
    _state = switch (_conn) {
      ConnectionStatus.disconnected => const TrackingOffline(),
      ConnectionStatus.connecting => const TrackingConnecting(),
      ConnectionStatus.reconnecting => const TrackingConnecting(),
      ConnectionStatus.connected => new TrackingOnline(
        connection: _conn,
        onDuty: _duty.onDuty,
        availability: _shownAvailability,
        permissionBlocked: _permissionBlocked,
        lastPing: _lastPing,
        lastMessage: _message,
      ),
    };
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_connSub?.cancel());
    unawaited(_pingSub?.cancel());
    unawaited(_availabilitySub?.cancel());
    unawaited(_problemSub?.cancel());
    unawaited(_jobSub?.cancel());
    unawaited(_endSub?.cancel());
    super.dispose();
  }
}
