import 'package:fleet_pulse_mobile/config/app_config.dart';
import 'package:fleet_pulse_mobile/config/app_config_check.dart';
import 'package:fleet_pulse_mobile/core/app_logger.dart';
import 'package:fleet_pulse_mobile/di/injection.dart';
import 'package:fleet_pulse_mobile/ui/app.dart';
import 'package:fleet_pulse_mobile/ui/config_error_app.dart';
import 'package:flutter/widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final List<String> problems = AppConfigCheck.problems(
    httpBase: AppConfig.httpBase,
    wsBase: AppConfig.wsBase,
  );

  if (problems.isNotEmpty) {
    AppLogger.error('refusing to start: ${problems.join(' ')}');
    runApp(new ConfigErrorApp(problems: problems));

    return;
  }

  await configureDependencies();
  runApp(const FleetPulseApp());
}
