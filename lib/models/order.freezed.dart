// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'order.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Order {

@OrderIdConverter() OrderId get id; OrderStatus get status;@JsonKey(name: 'weight_kg') int get weightKg; LatLng get pickup; LatLng get dropoff;@JsonKey(name: 'assigned_at') DateTime get assignedAt;@JsonKey(name: 'pod_photo_url') String? get podPhotoUrl;@JsonKey(name: 'pod_signature') String? get podSignature;
/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrderCopyWith<Order> get copyWith => _$OrderCopyWithImpl<Order>(this as Order, _$identity);

  /// Serializes this Order to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Order&&(identical(other.id, id) || other.id == id)&&(identical(other.status, status) || other.status == status)&&(identical(other.weightKg, weightKg) || other.weightKg == weightKg)&&(identical(other.pickup, pickup) || other.pickup == pickup)&&(identical(other.dropoff, dropoff) || other.dropoff == dropoff)&&(identical(other.assignedAt, assignedAt) || other.assignedAt == assignedAt)&&(identical(other.podPhotoUrl, podPhotoUrl) || other.podPhotoUrl == podPhotoUrl)&&(identical(other.podSignature, podSignature) || other.podSignature == podSignature));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,status,weightKg,pickup,dropoff,assignedAt,podPhotoUrl,podSignature);

@override
String toString() {
  return 'Order(id: $id, status: $status, weightKg: $weightKg, pickup: $pickup, dropoff: $dropoff, assignedAt: $assignedAt, podPhotoUrl: $podPhotoUrl, podSignature: $podSignature)';
}


}

/// @nodoc
abstract mixin class $OrderCopyWith<$Res>  {
  factory $OrderCopyWith(Order value, $Res Function(Order) _then) = _$OrderCopyWithImpl;
@useResult
$Res call({
@OrderIdConverter() OrderId id, OrderStatus status,@JsonKey(name: 'weight_kg') int weightKg, LatLng pickup, LatLng dropoff,@JsonKey(name: 'assigned_at') DateTime assignedAt,@JsonKey(name: 'pod_photo_url') String? podPhotoUrl,@JsonKey(name: 'pod_signature') String? podSignature
});


$LatLngCopyWith<$Res> get pickup;$LatLngCopyWith<$Res> get dropoff;

}
/// @nodoc
class _$OrderCopyWithImpl<$Res>
    implements $OrderCopyWith<$Res> {
  _$OrderCopyWithImpl(this._self, this._then);

  final Order _self;
  final $Res Function(Order) _then;

/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? status = null,Object? weightKg = null,Object? pickup = null,Object? dropoff = null,Object? assignedAt = null,Object? podPhotoUrl = freezed,Object? podSignature = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as OrderId,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as OrderStatus,weightKg: null == weightKg ? _self.weightKg : weightKg // ignore: cast_nullable_to_non_nullable
as int,pickup: null == pickup ? _self.pickup : pickup // ignore: cast_nullable_to_non_nullable
as LatLng,dropoff: null == dropoff ? _self.dropoff : dropoff // ignore: cast_nullable_to_non_nullable
as LatLng,assignedAt: null == assignedAt ? _self.assignedAt : assignedAt // ignore: cast_nullable_to_non_nullable
as DateTime,podPhotoUrl: freezed == podPhotoUrl ? _self.podPhotoUrl : podPhotoUrl // ignore: cast_nullable_to_non_nullable
as String?,podSignature: freezed == podSignature ? _self.podSignature : podSignature // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LatLngCopyWith<$Res> get pickup {
  
  return $LatLngCopyWith<$Res>(_self.pickup, (value) {
    return _then(_self.copyWith(pickup: value));
  });
}/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LatLngCopyWith<$Res> get dropoff {
  
  return $LatLngCopyWith<$Res>(_self.dropoff, (value) {
    return _then(_self.copyWith(dropoff: value));
  });
}
}


/// Adds pattern-matching-related methods to [Order].
extension OrderPatterns on Order {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Order value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Order() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Order value)  $default,){
final _that = this;
switch (_that) {
case _Order():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Order value)?  $default,){
final _that = this;
switch (_that) {
case _Order() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@OrderIdConverter()  OrderId id,  OrderStatus status, @JsonKey(name: 'weight_kg')  int weightKg,  LatLng pickup,  LatLng dropoff, @JsonKey(name: 'assigned_at')  DateTime assignedAt, @JsonKey(name: 'pod_photo_url')  String? podPhotoUrl, @JsonKey(name: 'pod_signature')  String? podSignature)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Order() when $default != null:
return $default(_that.id,_that.status,_that.weightKg,_that.pickup,_that.dropoff,_that.assignedAt,_that.podPhotoUrl,_that.podSignature);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@OrderIdConverter()  OrderId id,  OrderStatus status, @JsonKey(name: 'weight_kg')  int weightKg,  LatLng pickup,  LatLng dropoff, @JsonKey(name: 'assigned_at')  DateTime assignedAt, @JsonKey(name: 'pod_photo_url')  String? podPhotoUrl, @JsonKey(name: 'pod_signature')  String? podSignature)  $default,) {final _that = this;
switch (_that) {
case _Order():
return $default(_that.id,_that.status,_that.weightKg,_that.pickup,_that.dropoff,_that.assignedAt,_that.podPhotoUrl,_that.podSignature);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@OrderIdConverter()  OrderId id,  OrderStatus status, @JsonKey(name: 'weight_kg')  int weightKg,  LatLng pickup,  LatLng dropoff, @JsonKey(name: 'assigned_at')  DateTime assignedAt, @JsonKey(name: 'pod_photo_url')  String? podPhotoUrl, @JsonKey(name: 'pod_signature')  String? podSignature)?  $default,) {final _that = this;
switch (_that) {
case _Order() when $default != null:
return $default(_that.id,_that.status,_that.weightKg,_that.pickup,_that.dropoff,_that.assignedAt,_that.podPhotoUrl,_that.podSignature);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Order implements Order {
  const _Order({@OrderIdConverter() required this.id, required this.status, @JsonKey(name: 'weight_kg') required this.weightKg, required this.pickup, required this.dropoff, @JsonKey(name: 'assigned_at') required this.assignedAt, @JsonKey(name: 'pod_photo_url') this.podPhotoUrl, @JsonKey(name: 'pod_signature') this.podSignature});
  factory _Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);

@override@OrderIdConverter() final  OrderId id;
@override final  OrderStatus status;
@override@JsonKey(name: 'weight_kg') final  int weightKg;
@override final  LatLng pickup;
@override final  LatLng dropoff;
@override@JsonKey(name: 'assigned_at') final  DateTime assignedAt;
@override@JsonKey(name: 'pod_photo_url') final  String? podPhotoUrl;
@override@JsonKey(name: 'pod_signature') final  String? podSignature;

/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrderCopyWith<_Order> get copyWith => __$OrderCopyWithImpl<_Order>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OrderToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Order&&(identical(other.id, id) || other.id == id)&&(identical(other.status, status) || other.status == status)&&(identical(other.weightKg, weightKg) || other.weightKg == weightKg)&&(identical(other.pickup, pickup) || other.pickup == pickup)&&(identical(other.dropoff, dropoff) || other.dropoff == dropoff)&&(identical(other.assignedAt, assignedAt) || other.assignedAt == assignedAt)&&(identical(other.podPhotoUrl, podPhotoUrl) || other.podPhotoUrl == podPhotoUrl)&&(identical(other.podSignature, podSignature) || other.podSignature == podSignature));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,status,weightKg,pickup,dropoff,assignedAt,podPhotoUrl,podSignature);

@override
String toString() {
  return 'Order(id: $id, status: $status, weightKg: $weightKg, pickup: $pickup, dropoff: $dropoff, assignedAt: $assignedAt, podPhotoUrl: $podPhotoUrl, podSignature: $podSignature)';
}


}

/// @nodoc
abstract mixin class _$OrderCopyWith<$Res> implements $OrderCopyWith<$Res> {
  factory _$OrderCopyWith(_Order value, $Res Function(_Order) _then) = __$OrderCopyWithImpl;
@override @useResult
$Res call({
@OrderIdConverter() OrderId id, OrderStatus status,@JsonKey(name: 'weight_kg') int weightKg, LatLng pickup, LatLng dropoff,@JsonKey(name: 'assigned_at') DateTime assignedAt,@JsonKey(name: 'pod_photo_url') String? podPhotoUrl,@JsonKey(name: 'pod_signature') String? podSignature
});


@override $LatLngCopyWith<$Res> get pickup;@override $LatLngCopyWith<$Res> get dropoff;

}
/// @nodoc
class __$OrderCopyWithImpl<$Res>
    implements _$OrderCopyWith<$Res> {
  __$OrderCopyWithImpl(this._self, this._then);

  final _Order _self;
  final $Res Function(_Order) _then;

/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? status = null,Object? weightKg = null,Object? pickup = null,Object? dropoff = null,Object? assignedAt = null,Object? podPhotoUrl = freezed,Object? podSignature = freezed,}) {
  return _then(_Order(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as OrderId,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as OrderStatus,weightKg: null == weightKg ? _self.weightKg : weightKg // ignore: cast_nullable_to_non_nullable
as int,pickup: null == pickup ? _self.pickup : pickup // ignore: cast_nullable_to_non_nullable
as LatLng,dropoff: null == dropoff ? _self.dropoff : dropoff // ignore: cast_nullable_to_non_nullable
as LatLng,assignedAt: null == assignedAt ? _self.assignedAt : assignedAt // ignore: cast_nullable_to_non_nullable
as DateTime,podPhotoUrl: freezed == podPhotoUrl ? _self.podPhotoUrl : podPhotoUrl // ignore: cast_nullable_to_non_nullable
as String?,podSignature: freezed == podSignature ? _self.podSignature : podSignature // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LatLngCopyWith<$Res> get pickup {
  
  return $LatLngCopyWith<$Res>(_self.pickup, (value) {
    return _then(_self.copyWith(pickup: value));
  });
}/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LatLngCopyWith<$Res> get dropoff {
  
  return $LatLngCopyWith<$Res>(_self.dropoff, (value) {
    return _then(_self.copyWith(dropoff: value));
  });
}
}

// dart format on
