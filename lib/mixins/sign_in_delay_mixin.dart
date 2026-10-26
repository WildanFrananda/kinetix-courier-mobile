import 'dart:async';

import 'package:clock/clock.dart';
import 'package:fleet_pulse_mobile/core/core.dart';
import 'package:flutter/foundation.dart';

mixin SignInDelayMixin on ChangeNotifier {
  static const Duration _tick = Duration(seconds: 1);

  DateTime? _retryAt;
  Timer? _ticker;

  bool get delayed => _left() != null;

  String? get delayMessage {
    final Duration? left = _left();

    return left == null ? null : SignInDelayedFailure.tryAgainIn(left);
  }

  void delayFor(Duration wait) {
    _retryAt = clock.now().add(wait);
    _ticker?.cancel();
    _ticker = new Timer.periodic(_tick, (_) => _onTick());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _ticker = null;
    super.dispose();
  }

  void _onTick() {
    if (_left() == null) {
      _ticker?.cancel();
      _ticker = null;
      _retryAt = null;
    }

    notifyListeners();
  }

  Duration? _left() {
    final DateTime? retryAt = _retryAt;
    if (retryAt == null) {
      return null;
    }

    final Duration left = retryAt.difference(clock.now());

    return left > Duration.zero ? left : null;
  }
}
