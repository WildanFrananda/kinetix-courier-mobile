// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:dio/dio.dart' as _i361;
import 'package:fleet_pulse_mobile/di/register_module.dart' as _i302;
import 'package:fleet_pulse_mobile/maps/maps_launcher.dart' as _i595;
import 'package:fleet_pulse_mobile/repositories/connection_repository.dart'
    as _i891;
import 'package:fleet_pulse_mobile/repositories/connection_repository_impl.dart'
    as _i458;
import 'package:fleet_pulse_mobile/repositories/order_repository.dart' as _i933;
import 'package:fleet_pulse_mobile/repositories/order_repository_impl.dart'
    as _i549;
import 'package:fleet_pulse_mobile/repositories/session_repository.dart'
    as _i968;
import 'package:fleet_pulse_mobile/repositories/session_repository_impl.dart'
    as _i670;
import 'package:fleet_pulse_mobile/repositories/telemetry_repository.dart'
    as _i85;
import 'package:fleet_pulse_mobile/repositories/telemetry_repository_impl.dart'
    as _i70;
import 'package:fleet_pulse_mobile/routes/app_router_state.dart' as _i34;
import 'package:fleet_pulse_mobile/services/auth/driver_api.dart' as _i738;
import 'package:fleet_pulse_mobile/services/auth/token_store.dart' as _i996;
import 'package:fleet_pulse_mobile/services/channel/channel_client.dart'
    as _i700;
import 'package:fleet_pulse_mobile/services/foreground/foreground_service_manager.dart'
    as _i333;
import 'package:fleet_pulse_mobile/services/location/location_service.dart'
    as _i826;
import 'package:fleet_pulse_mobile/services/storage/pod_photo_uploader.dart'
    as _i465;
import 'package:fleet_pulse_mobile/viewmodels/login_view_model.dart' as _i598;
import 'package:fleet_pulse_mobile/viewmodels/order_view_model.dart' as _i962;
import 'package:fleet_pulse_mobile/viewmodels/pending_approval_view_model.dart'
    as _i68;
import 'package:fleet_pulse_mobile/viewmodels/register_view_model.dart'
    as _i561;
import 'package:fleet_pulse_mobile/viewmodels/splash_view_model.dart' as _i580;
import 'package:fleet_pulse_mobile/viewmodels/tracking_view_model.dart'
    as _i812;
import 'package:flutter_secure_storage/flutter_secure_storage.dart' as _i558;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final registerModule = _$RegisterModule();
    gh.singleton<_i34.AppRouterState>(() => _i34.AppRouterState());
    gh.lazySingleton<_i361.Dio>(() => registerModule.dio);
    gh.lazySingleton<_i558.FlutterSecureStorage>(
      () => registerModule.secureStorage,
    );
    gh.lazySingleton<_i595.MapsLauncher>(() => _i595.MapsLauncher());
    gh.lazySingleton<_i700.ChannelClient>(
      () => _i700.ChannelClient(),
      dispose: (i) => i.dispose(),
    );
    gh.lazySingleton<_i333.ForegroundServiceManager>(
      () => _i333.ForegroundServiceManager(),
    );
    gh.lazySingleton<_i826.LocationService>(() => _i826.LocationService());
    gh.lazySingleton<_i361.Dio>(
      () => registerModule.storageDio,
      instanceName: 'storage',
    );
    gh.lazySingleton<_i996.TokenStore>(
      () => _i996.TokenStore(gh<_i558.FlutterSecureStorage>()),
    );
    gh.lazySingleton<_i465.PodPhotoUploader>(
      () => _i465.PodPhotoUploader(gh<_i361.Dio>(instanceName: 'storage')),
    );
    gh.lazySingleton<_i933.OrderRepository>(
      () => _i549.OrderRepositoryImpl(
        gh<_i700.ChannelClient>(),
        gh<_i465.PodPhotoUploader>(),
      ),
    );
    gh.lazySingleton<_i738.DriverApi>(
      () => registerModule.driverApi(gh<_i361.Dio>()),
    );
    gh.factory<_i68.PendingApprovalViewModel>(
      () => _i68.PendingApprovalViewModel(gh<_i34.AppRouterState>()),
    );
    gh.lazySingleton<_i891.ConnectionRepository>(
      () => _i458.ConnectionRepositoryImpl(gh<_i700.ChannelClient>()),
    );
    gh.lazySingleton<_i85.TelemetryRepository>(
      () => _i70.TelemetryRepositoryImpl(
        gh<_i826.LocationService>(),
        gh<_i700.ChannelClient>(),
        gh<_i333.ForegroundServiceManager>(),
      ),
      dispose: (i) => i.dispose(),
    );
    gh.lazySingleton<_i968.SessionRepository>(
      () => _i670.SessionRepositoryImpl(
        gh<_i738.DriverApi>(),
        gh<_i996.TokenStore>(),
      ),
    );
    gh.factory<_i962.OrderViewModel>(
      () => _i962.OrderViewModel(
        gh<_i34.AppRouterState>(),
        gh<_i933.OrderRepository>(),
        gh<_i595.MapsLauncher>(),
      ),
    );
    gh.factory<_i812.TrackingViewModel>(
      () => _i812.TrackingViewModel(
        gh<_i34.AppRouterState>(),
        gh<_i891.ConnectionRepository>(),
        gh<_i933.OrderRepository>(),
        gh<_i85.TelemetryRepository>(),
        gh<_i968.SessionRepository>(),
      ),
    );
    gh.factory<_i598.LoginViewModel>(
      () => _i598.LoginViewModel(
        gh<_i34.AppRouterState>(),
        gh<_i968.SessionRepository>(),
      ),
    );
    gh.factory<_i561.RegisterViewModel>(
      () => _i561.RegisterViewModel(
        gh<_i34.AppRouterState>(),
        gh<_i968.SessionRepository>(),
      ),
    );
    gh.factory<_i580.SplashViewModel>(
      () => _i580.SplashViewModel(
        gh<_i34.AppRouterState>(),
        gh<_i968.SessionRepository>(),
      ),
    );
    return this;
  }
}

class _$RegisterModule extends _i302.RegisterModule {}
