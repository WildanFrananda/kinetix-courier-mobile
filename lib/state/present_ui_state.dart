import 'package:fleet_pulse_mobile/core/core.dart';
import 'package:fleet_pulse_mobile/models/models.dart';

sealed class PresentUiState {
  const PresentUiState();
}

class PresentScanning extends PresentUiState {
  const PresentScanning({this.error});

  final Failure? error;
}

class PresentAsking extends PresentUiState {
  const PresentAsking(this.offer, {this.error});

  final PresentationOffer offer;
  final Failure? error;
}

class PresentProving extends PresentUiState {
  const PresentProving(this.offer);

  final PresentationOffer offer;
}

class PresentAnswering extends PresentUiState {
  const PresentAnswering(this.offer, this.answer, this.frame);

  final PresentationOffer offer;
  final PresentedAnswer answer;
  final int frame;
}
