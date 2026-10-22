import 'package:fleet_pulse_mobile/models/ids.dart';
import 'package:fleet_pulse_mobile/models/order.dart';

sealed class ServerEvent {
  const ServerEvent();
}

class ActiveOrderEvent extends ServerEvent {
  const ActiveOrderEvent(this.order);

  final Order? order;
}

class OrderAssignedEvent extends ServerEvent {
  const OrderAssignedEvent(this.order);

  final Order order;
}

class OrderUpdatedEvent extends ServerEvent {
  const OrderUpdatedEvent(this.order);

  final Order? order;
}

class OrderUnassignedEvent extends ServerEvent {
  const OrderUnassignedEvent(this.id);

  final OrderId id;
}
