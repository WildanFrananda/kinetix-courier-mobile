import 'package:fleet_pulse_mobile/config/app_check_mode.dart';
import 'package:fleet_pulse_mobile/config/app_config.dart';
import 'package:fleet_pulse_mobile/config/app_config_check.dart';
import 'package:fleet_pulse_mobile/core/app_logger.dart';
import 'package:fleet_pulse_mobile/di/injection.dart';
import 'package:fleet_pulse_mobile/services/attestation/app_check_activation.dart';
import 'package:fleet_pulse_mobile/ui/app.dart';
import 'package:fleet_pulse_mobile/ui/config_error_app.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final List<String> problems = AppConfigCheck.problems(
    httpBase: AppConfig.httpBase,
    wsBase: AppConfig.wsBase,
    firebase: AppConfig.firebaseDefines,
    appCheckProvider: AppConfig.appCheckProvider,
    releaseBuild: kReleaseMode,
  );
  final AppCheckMode? mode = AppCheckMode.fromDefine(
    AppConfig.appCheckProvider,
  );

  if (problems.isNotEmpty || mode == null) {
    _refuseToStart(problems);

    return;
  }

  final String? attestation = await AppCheckActivation.start(mode);

  if (attestation != null) {
    _refuseToStart(<String>[attestation]);

    return;
  }

  await configureDependencies();
  runApp(const FleetPulseApp());
}

void _refuseToStart(List<String> problems) {
  AppLogger.error('refusing to start: ${problems.join(' ')}');
  runApp(new ConfigErrorApp(problems: problems));
}
