import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kinetix_courier/models/converters.dart';
import 'package:kinetix_courier/models/enums.dart';
import 'package:kinetix_courier/models/ids.dart';
import 'package:kinetix_courier/models/lat_lng.dart';

part 'order.freezed.dart';
part 'order.g.dart';

@freezed
abstract class Order with _$Order {
  const factory Order({
    @OrderIdConverter() required OrderId id,
    required OrderStatus status,
    required int weightKg,
    required LatLng pickup,
    required LatLng dropoff,
    required DateTime assignedAt,
    String? orderNumber,
    String? podPhotoUrl,
    String? podSignature,
  }) = _Order;

  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);
}
