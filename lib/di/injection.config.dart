// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:dio/dio.dart' as _i361;
import 'package:flutter_secure_storage/flutter_secure_storage.dart' as _i558;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:kinetix_courier/di/register_module.dart' as _i365;
import 'package:kinetix_courier/maps/maps_launcher.dart' as _i2;
import 'package:kinetix_courier/repositories/connection_repository.dart'
    as _i418;
import 'package:kinetix_courier/repositories/connection_repository_impl.dart'
    as _i36;
import 'package:kinetix_courier/repositories/credential_repository.dart'
    as _i947;
import 'package:kinetix_courier/repositories/credential_repository_impl.dart'
    as _i201;
import 'package:kinetix_courier/repositories/duty_repository.dart' as _i985;
import 'package:kinetix_courier/repositories/duty_repository_impl.dart'
    as _i348;
import 'package:kinetix_courier/repositories/order_repository.dart' as _i965;
import 'package:kinetix_courier/repositories/order_repository_impl.dart'
    as _i212;
import 'package:kinetix_courier/repositories/session_repository.dart' as _i373;
import 'package:kinetix_courier/repositories/session_repository_impl.dart'
    as _i488;
import 'package:kinetix_courier/routes/app_router_state.dart' as _i662;
import 'package:kinetix_courier/services/attestation/client_proof.dart'
    as _i654;
import 'package:kinetix_courier/services/attestation/client_proof_source.dart'
    as _i327;
import 'package:kinetix_courier/services/attestation/firebase_client_proof_source.dart'
    as _i151;
import 'package:kinetix_courier/services/auth/driver_api.dart' as _i840;
import 'package:kinetix_courier/services/auth/fleet_standing.dart' as _i857;
import 'package:kinetix_courier/services/auth/session_renewer.dart' as _i309;
import 'package:kinetix_courier/services/auth/token_store.dart' as _i1042;
import 'package:kinetix_courier/services/channel/channel_client.dart' as _i224;
import 'package:kinetix_courier/services/device/screen_wake.dart' as _i61;
import 'package:kinetix_courier/services/device/share_sheet.dart' as _i59;
import 'package:kinetix_courier/services/location/location_service.dart'
    as _i1004;
import 'package:kinetix_courier/services/offline/offline_position_store.dart'
    as _i157;
import 'package:kinetix_courier/services/seal/holder_runtime.dart' as _i485;
import 'package:kinetix_courier/services/seal/holder_vault.dart' as _i841;
import 'package:kinetix_courier/services/seal/seal_api.dart' as _i559;
import 'package:kinetix_courier/services/storage/pod_photo_uploader.dart'
    as _i557;
import 'package:kinetix_courier/services/storage/proof_draft_store.dart'
    as _i199;
import 'package:kinetix_courier/viewmodels/credential_view_model.dart' as _i291;
import 'package:kinetix_courier/viewmodels/login_view_model.dart' as _i1002;
import 'package:kinetix_courier/viewmodels/order_view_model.dart' as _i1062;
import 'package:kinetix_courier/viewmodels/pending_approval_view_model.dart'
    as _i1002;
import 'package:kinetix_courier/viewmodels/present_view_model.dart' as _i898;
import 'package:kinetix_courier/viewmodels/register_view_model.dart' as _i521;
import 'package:kinetix_courier/viewmodels/splash_view_model.dart' as _i1062;
import 'package:kinetix_courier/viewmodels/tracking_view_model.dart' as _i1038;
import 'package:kinetix_courier/viewmodels/update_required_view_model.dart'
    as _i91;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final registerModule = _$RegisterModule();
    gh.singleton<_i662.AppRouterState>(() => _i662.AppRouterState());
    gh.lazySingleton<_i361.Dio>(() => registerModule.dio);
    gh.lazySingleton<_i558.FlutterSecureStorage>(
      () => registerModule.secureStorage,
    );
    gh.lazySingleton<_i2.MapsLauncher>(() => _i2.MapsLauncher());
    gh.lazySingleton<_i224.ChannelClient>(
      () => _i224.ChannelClient(),
      dispose: (i) => i.dispose(),
    );
    gh.lazySingleton<_i61.ScreenWake>(() => _i61.ScreenWake());
    gh.lazySingleton<_i59.ShareSheet>(() => _i59.ShareSheet());
    gh.lazySingleton<_i1004.LocationService>(() => _i1004.LocationService());
    gh.lazySingleton<_i157.OfflinePositionStore>(
      () => _i157.OfflinePositionStore(),
    );
    gh.lazySingleton<_i485.HolderRuntime>(() => _i485.HolderRuntime());
    gh.lazySingleton<_i199.ProofDraftStore>(() => _i199.ProofDraftStore());
    gh.lazySingleton<_i327.ClientProofSource>(
      () => _i151.FirebaseClientProofSource(),
    );
    gh.lazySingleton<_i361.Dio>(
      () => registerModule.storageDio,
      instanceName: 'storage',
    );
    gh.lazySingleton<_i1042.TokenStore>(
      () => _i1042.TokenStore(gh<_i558.FlutterSecureStorage>()),
    );
    gh.lazySingleton<_i841.HolderVault>(
      () => _i841.HolderVault(gh<_i558.FlutterSecureStorage>()),
    );
    gh.lazySingleton<_i557.PodPhotoUploader>(
      () => _i557.PodPhotoUploader(gh<_i361.Dio>(instanceName: 'storage')),
    );
    gh.lazySingleton<_i985.DutyRepository>(
      () => _i348.DutyRepositoryImpl(
        gh<_i1004.LocationService>(),
        gh<_i224.ChannelClient>(),
        gh<_i157.OfflinePositionStore>(),
      ),
      dispose: (i) => i.dispose(),
    );
    gh.lazySingleton<_i840.DriverApi>(
      () => registerModule.driverApi(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i559.SealApi>(
      () => registerModule.sealApi(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i965.OrderRepository>(
      () => _i212.OrderRepositoryImpl(
        gh<_i224.ChannelClient>(),
        gh<_i557.PodPhotoUploader>(),
        gh<_i199.ProofDraftStore>(),
      ),
    );
    gh.lazySingleton<_i654.ClientProof>(
      () => _i654.ClientProof(gh<_i327.ClientProofSource>()),
    );
    gh.factory<_i1062.OrderViewModel>(
      () => _i1062.OrderViewModel(
        gh<_i662.AppRouterState>(),
        gh<_i965.OrderRepository>(),
        gh<_i2.MapsLauncher>(),
      ),
    );
    gh.lazySingleton<_i309.SessionRenewer>(
      () => _i309.SessionRenewer(
        gh<_i840.DriverApi>(),
        gh<_i1042.TokenStore>(),
        gh<_i654.ClientProof>(),
      ),
    );
    gh.factory<_i91.UpdateRequiredViewModel>(
      () => _i91.UpdateRequiredViewModel(gh<_i662.AppRouterState>()),
    );
    gh.lazySingleton<_i947.CredentialRepository>(
      () => _i201.CredentialRepositoryImpl(
        gh<_i559.SealApi>(),
        gh<_i1042.TokenStore>(),
        gh<_i309.SessionRenewer>(),
        gh<_i841.HolderVault>(),
        gh<_i485.HolderRuntime>(),
      ),
    );
    gh.factory<_i898.PresentViewModel>(
      () => _i898.PresentViewModel(
        gh<_i662.AppRouterState>(),
        gh<_i947.CredentialRepository>(),
        gh<_i485.HolderRuntime>(),
        gh<_i61.ScreenWake>(),
        gh<_i59.ShareSheet>(),
      ),
    );
    gh.lazySingleton<_i857.FleetStanding>(
      () => _i857.FleetStanding(gh<_i840.DriverApi>()),
    );
    gh.lazySingleton<_i373.SessionRepository>(
      () => _i488.SessionRepositoryImpl(
        gh<_i840.DriverApi>(),
        gh<_i1042.TokenStore>(),
        gh<_i309.SessionRenewer>(),
        gh<_i857.FleetStanding>(),
        gh<_i654.ClientProof>(),
      ),
    );
    gh.factory<_i291.CredentialViewModel>(
      () => _i291.CredentialViewModel(
        gh<_i662.AppRouterState>(),
        gh<_i947.CredentialRepository>(),
        gh<_i485.HolderRuntime>(),
      ),
    );
    gh.factory<_i1002.LoginViewModel>(
      () => _i1002.LoginViewModel(
        gh<_i662.AppRouterState>(),
        gh<_i373.SessionRepository>(),
      ),
    );
    gh.factory<_i1002.PendingApprovalViewModel>(
      () => _i1002.PendingApprovalViewModel(
        gh<_i662.AppRouterState>(),
        gh<_i373.SessionRepository>(),
      ),
    );
    gh.factory<_i521.RegisterViewModel>(
      () => _i521.RegisterViewModel(
        gh<_i662.AppRouterState>(),
        gh<_i373.SessionRepository>(),
      ),
    );
    gh.factory<_i1062.SplashViewModel>(
      () => _i1062.SplashViewModel(
        gh<_i662.AppRouterState>(),
        gh<_i373.SessionRepository>(),
      ),
    );
    gh.lazySingleton<_i418.ConnectionRepository>(
      () => _i36.ConnectionRepositoryImpl(
        gh<_i224.ChannelClient>(),
        gh<_i309.SessionRenewer>(),
        gh<_i857.FleetStanding>(),
        gh<_i1042.TokenStore>(),
      ),
      dispose: (i) => i.dispose(),
    );
    gh.factory<_i1038.TrackingViewModel>(
      () => _i1038.TrackingViewModel(
        gh<_i662.AppRouterState>(),
        gh<_i418.ConnectionRepository>(),
        gh<_i965.OrderRepository>(),
        gh<_i985.DutyRepository>(),
        gh<_i373.SessionRepository>(),
      ),
    );
    return this;
  }
}

class _$RegisterModule extends _i365.RegisterModule {}
