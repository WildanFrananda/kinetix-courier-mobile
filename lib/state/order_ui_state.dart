import 'package:fleet_pulse_mobile/core/core.dart';
import 'package:fleet_pulse_mobile/models/models.dart';

sealed class OrderUiState {
  const OrderUiState();
}

class OrderShowing extends OrderUiState {
  const OrderShowing(this.order, {this.submitting = false, this.error});

  final Order order;
  final bool submitting;
  final Failure? error;
}

class OrderCancelled extends OrderUiState {
  const OrderCancelled();
}

class OrderUnassigned extends OrderUiState {
  const OrderUnassigned();
}

class OrderNoLongerActive extends OrderUiState {
  const OrderNoLongerActive();
}
