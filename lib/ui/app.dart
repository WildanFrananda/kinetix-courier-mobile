import 'package:flutter/material.dart';
import 'package:kinetix_courier/di/injection.dart';
import 'package:kinetix_courier/repositories/connection_repository.dart';
import 'package:kinetix_courier/routes/app_route_mapper.dart';
import 'package:kinetix_courier/routes/app_router_state.dart';
import 'package:provider/provider.dart';

class KinetixCourierApp extends StatefulWidget {
  const KinetixCourierApp({super.key});

  @override
  State<KinetixCourierApp> createState() => _KinetixCourierAppState();
}

class _KinetixCourierAppState extends State<KinetixCourierApp> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = new AppLifecycleListener(
      onResume: () => getIt<ConnectionRepository>().onResume(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AppRouterState>.value(
      value: getIt<AppRouterState>(),
      child: MaterialApp(
        title: 'Kinetix Courier',
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
        home: const _RouterHost(),
      ),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }
}

class _RouterHost extends StatelessWidget {
  const _RouterHost();

  @override
  Widget build(BuildContext context) {
    final AppRouterState router = context.watch<AppRouterState>();
    const AppRouteMapper mapper = AppRouteMapper();

    return Navigator(
      pages: <Page<dynamic>>[
        for (final route in router.stack) mapper.toPage(route),
      ],
      onDidRemovePage: (Page<dynamic> page) => router.pop(),
    );
  }
}
