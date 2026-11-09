import 'package:json_annotation/json_annotation.dart';
import 'package:kinetix_courier/models/ids.dart';

class DriverIdConverter implements JsonConverter<DriverId, int> {
  const DriverIdConverter();

  @override
  DriverId fromJson(int json) => DriverId(json);

  @override
  int toJson(DriverId object) => object.value;
}

class OrderIdConverter implements JsonConverter<OrderId, int> {
  const OrderIdConverter();

  @override
  OrderId fromJson(int json) => OrderId(json);

  @override
  int toJson(OrderId object) => object.value;
}
