import 'package:injectable/injectable.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

@lazySingleton
class ScreenWake {
  Future<void> keepOn() {
    return WakelockPlus.enable();
  }

  Future<void> release() {
    return WakelockPlus.disable();
  }
}
