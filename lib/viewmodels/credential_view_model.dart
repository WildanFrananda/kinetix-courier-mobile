import 'dart:async';

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

  static const Duration pendingCheck = Duration(seconds: 20);

  final AppRouterState _router;

  final CredentialRepository _credentials;

  final HolderRuntime _runtime;

  CredentialUiState _state = const CredentialLoading();

  Timer? _pendingTimer;

  bool _checking = false;

  bool _disposed = false;

  CredentialUiState get state => _state;

  WebViewController get holder => _runtime.controller;

  bool get _isRequesting => switch (_state) {
    CredentialLoading() => false,
    CredentialAbsent(:final bool requesting) => requesting,
    CredentialShowing(:final bool requesting) => requesting,
  };

  Failure? get _shownError => switch (_state) {
    CredentialShowing(:final Failure? error) => error,
    _ => null,
  };

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

    if (_disposed) {
      return;
    }

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
    _followPending();
    notifyListeners();
  }

  void showToVerifier() {
    _router.push(const PresentRoute());
  }

  void back() {
    _router.pop();
  }

  @override
  void dispose() {
    _disposed = true;
    _pendingTimer?.cancel();
    super.dispose();
  }

  void _apply(
    Result<CourierCredential?> current, {
    required bool requesting,
    Failure? error,
  }) {
    if (_disposed) {
      return;
    }

    _state = current.fold(
      (CourierCredential? credential) => credential == null
          ? new CredentialAbsent(requesting: requesting)
          : new CredentialShowing(
              credential,
              requesting: requesting,
              error: error,
            ),
      (Failure failure) => new CredentialAbsent(error: failure),
    );
    _leaveIfSignedOut(current);
    _followPending();
    notifyListeners();
  }

  void _followPending() {
    final CredentialUiState state = _state;
    final bool pending =
        state is CredentialShowing &&
        state.credential.standing == CredentialStanding.pending;

    if (!pending) {
      _pendingTimer?.cancel();
      _pendingTimer = null;

      return;
    }

    _pendingTimer ??= new Timer.periodic(pendingCheck, (_) {
      unawaited(_checkPending());
    });
  }

  Future<void> _checkPending() async {
    if (_checking || _isRequesting) {
      return;
    }

    _checking = true;

    final Result<CourierCredential?> current;

    try {
      current = await _credentials.current();
    } finally {
      _checking = false;
    }

    if (_isRequesting) {
      return;
    }

    _apply(current, requesting: false, error: _shownError);
  }

  void _leaveIfSignedOut<T>(Result<T> result) {
    if (result case Err<T>(
      :final Failure failure,
    ) when failure is AuthFailure) {
      _router.replaceAll(const LoginRoute());
    }
  }
}
