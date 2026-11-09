// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Order _$OrderFromJson(Map<String, dynamic> json) => _Order(
  id: const OrderIdConverter().fromJson((json['id'] as num).toInt()),
  status: $enumDecode(_$OrderStatusEnumMap, json['status']),
  weightKg: (json['weight_kg'] as num).toInt(),
  pickup: LatLng.fromJson(json['pickup'] as Map<String, dynamic>),
  dropoff: LatLng.fromJson(json['dropoff'] as Map<String, dynamic>),
  assignedAt: DateTime.parse(json['assigned_at'] as String),
  podPhotoUrl: json['pod_photo_url'] as String?,
  podSignature: json['pod_signature'] as String?,
);

Map<String, dynamic> _$OrderToJson(_Order instance) => <String, dynamic>{
  'id': const OrderIdConverter().toJson(instance.id),
  'status': _$OrderStatusEnumMap[instance.status]!,
  'weight_kg': instance.weightKg,
  'pickup': instance.pickup,
  'dropoff': instance.dropoff,
  'assigned_at': instance.assignedAt.toIso8601String(),
  'pod_photo_url': instance.podPhotoUrl,
  'pod_signature': instance.podSignature,
};

const _$OrderStatusEnumMap = {
  OrderStatus.pending: 'pending',
  OrderStatus.assigned: 'assigned',
  OrderStatus.pickedUp: 'picked_up',
  OrderStatus.delivered: 'delivered',
  OrderStatus.cancelled: 'cancelled',
};
