import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:kinetix_courier/core/core.dart';
import 'package:kinetix_courier/models/models.dart';
import 'package:kinetix_courier/repositories/credential_repository.dart';
import 'package:kinetix_courier/routes/app_router_state.dart';
import 'package:kinetix_courier/services/device/screen_wake.dart';
import 'package:kinetix_courier/services/device/share_sheet.dart';
import 'package:kinetix_courier/services/seal/holder_runtime.dart';
import 'package:kinetix_courier/state/present_ui_state.dart';
import 'package:webview_flutter/webview_flutter.dart';

@injectable
class PresentViewModel extends ChangeNotifier {
  PresentViewModel(
    this._router,
    this._credentials,
    this._runtime,
    this._wake,
    this._share,
  );

  static const Duration frameInterval = Duration(milliseconds: 250);

  final AppRouterState _router;

  final CredentialRepository _credentials;

  final HolderRuntime _runtime;

  final ScreenWake _wake;

  final ShareSheet _share;

  PresentUiState _state = const PresentScanning();

  Timer? _frames;

  bool _reading = false;

  PresentUiState get state => _state;

  WebViewController get holder => _runtime.controller;

  Future<void> scanned(String text) async {
    if (_reading || _state is! PresentScanning) {
      return;
    }

    _reading = true;

    final Result<PresentationOffer> offer = await _credentials.offerFor(text);

    _reading = false;
    _state = offer.fold(
      PresentAsking.new,
      (Failure failure) => new PresentScanning(error: failure),
    );
    notifyListeners();
  }

  Future<void> confirm() async {
    final PresentUiState asked = _state;

    if (asked is! PresentAsking) {
      return;
    }

    _state = new PresentProving(asked.offer);
    notifyListeners();
    await _wake.keepOn();

    final Result<PresentedAnswer> answer = await _credentials.present(
      asked.offer,
    );

    await _wake.release();
    _state = answer.fold(
      (PresentedAnswer value) => new PresentAnswering(asked.offer, value, 0),
      (Failure failure) => new PresentAsking(asked.offer, error: failure),
    );

    if (_state is PresentAnswering) {
      _frames = new Timer.periodic(frameInterval, (_) => _nextFrame());
    }

    notifyListeners();
  }

  Future<void> shareLink() async {
    if (_state case PresentAnswering(:final PresentedAnswer answer)) {
      await _share.share(answer.link.toString());
    }
  }

  void decline() {
    _stopFrames();
    _state = const PresentScanning();
    notifyListeners();
  }

  void done() {
    _stopFrames();
    _router.pop();
  }

  void _nextFrame() {
    if (_state case PresentAnswering(
      :final PresentationOffer offer,
      :final PresentedAnswer answer,
      :final int frame,
    )) {
      _state = new PresentAnswering(
        offer,
        answer,
        (frame + 1) % answer.frames.length,
      );
      notifyListeners();
    }
  }

  void _stopFrames() {
    _frames?.cancel();
    _frames = null;
  }

  @override
  void dispose() {
    _stopFrames();
    super.dispose();
  }
}
