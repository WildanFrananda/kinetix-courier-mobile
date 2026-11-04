import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:kinetix_courier/core/core.dart';
import 'package:kinetix_courier/models/models.dart';
import 'package:kinetix_courier/repositories/credential_repository.dart';
import 'package:kinetix_courier/routes/app_route.dart';
import 'package:kinetix_courier/routes/app_router_state.dart';
import 'package:kinetix_courier/services/seal/holder_runtime.dart';
import 'package:kinetix_courier/state/credential_ui_state.dart';
import 'package:webview_flutter/webview_flutter.dart';

@injectable
class CredentialViewModel extends ChangeNotifier {
  CredentialViewModel(this._router, this._credentials, this._runtime);

  final AppRouterState _router;

  final CredentialRepository _credentials;

  final HolderRuntime _runtime;

  CredentialUiState _state = const CredentialLoading();

  CredentialUiState get state => _state;

  WebViewController get holder => _runtime.controller;

  Future<void> load() async {
    await _credentials.refreshPublicState(force: false);

    final Result<CourierCredential?> current = await _credentials.current();

    _apply(current, requesting: false);
    await _credentials.prepareHolder();
  }

  Future<void> request() async {
    _state = switch (_state) {
      CredentialShowing(:final CourierCredential credential) =>
        new CredentialShowing(credential, requesting: true),
      _ => const CredentialAbsent(requesting: true),
    };
    notifyListeners();

    await _credentials.refreshPublicState(force: true);

    final Result<CourierCredential> requested = await _credentials.request();

    requested.fold(
      (CourierCredential credential) =>
          _state = new CredentialShowing(credential),
      (Failure failure) => _state = switch (_state) {
        CredentialShowing(:final CourierCredential credential) =>
          new CredentialShowing(credential, error: failure),
        _ => new CredentialAbsent(error: failure),
      },
    );
    _leaveIfSignedOut(requested);
    notifyListeners();
  }

  void showToVerifier() {
    _router.push(const PresentRoute());
  }

  void back() {
    _router.pop();
  }

  void _apply(Result<CourierCredential?> current, {required bool requesting}) {
    _state = current.fold(
      (CourierCredential? credential) => credential == null
          ? new CredentialAbsent(requesting: requesting)
          : new CredentialShowing(credential, requesting: requesting),
      (Failure failure) => new CredentialAbsent(error: failure),
    );
    _leaveIfSignedOut(current);
    notifyListeners();
  }

  void _leaveIfSignedOut<T>(Result<T> result) {
    if (result case Err<T>(
      :final Failure failure,
    ) when failure is AuthFailure) {
      _router.replaceAll(const LoginRoute());
    }
  }
}
