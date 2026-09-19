// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'driver_profile_envelope.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DriverProfileEnvelope {

 DriverProfile get data;
/// Create a copy of DriverProfileEnvelope
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DriverProfileEnvelopeCopyWith<DriverProfileEnvelope> get copyWith => _$DriverProfileEnvelopeCopyWithImpl<DriverProfileEnvelope>(this as DriverProfileEnvelope, _$identity);

  /// Serializes this DriverProfileEnvelope to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DriverProfileEnvelope&&(identical(other.data, data) || other.data == data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,data);

@override
String toString() {
  return 'DriverProfileEnvelope(data: $data)';
}


}

/// @nodoc
abstract mixin class $DriverProfileEnvelopeCopyWith<$Res>  {
  factory $DriverProfileEnvelopeCopyWith(DriverProfileEnvelope value, $Res Function(DriverProfileEnvelope) _then) = _$DriverProfileEnvelopeCopyWithImpl;
@useResult
$Res call({
 DriverProfile data
});


$DriverProfileCopyWith<$Res> get data;

}
/// @nodoc
class _$DriverProfileEnvelopeCopyWithImpl<$Res>
    implements $DriverProfileEnvelopeCopyWith<$Res> {
  _$DriverProfileEnvelopeCopyWithImpl(this._self, this._then);

  final DriverProfileEnvelope _self;
  final $Res Function(DriverProfileEnvelope) _then;

/// Create a copy of DriverProfileEnvelope
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? data = null,}) {
  return _then(_self.copyWith(
data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as DriverProfile,
  ));
}
/// Create a copy of DriverProfileEnvelope
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DriverProfileCopyWith<$Res> get data {
  
  return $DriverProfileCopyWith<$Res>(_self.data, (value) {
    return _then(_self.copyWith(data: value));
  });
}
}


/// Adds pattern-matching-related methods to [DriverProfileEnvelope].
extension DriverProfileEnvelopePatterns on DriverProfileEnvelope {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DriverProfileEnvelope value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DriverProfileEnvelope() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DriverProfileEnvelope value)  $default,){
final _that = this;
switch (_that) {
case _DriverProfileEnvelope():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DriverProfileEnvelope value)?  $default,){
final _that = this;
switch (_that) {
case _DriverProfileEnvelope() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DriverProfile data)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DriverProfileEnvelope() when $default != null:
return $default(_that.data);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DriverProfile data)  $default,) {final _that = this;
switch (_that) {
case _DriverProfileEnvelope():
return $default(_that.data);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DriverProfile data)?  $default,) {final _that = this;
switch (_that) {
case _DriverProfileEnvelope() when $default != null:
return $default(_that.data);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DriverProfileEnvelope implements DriverProfileEnvelope {
  const _DriverProfileEnvelope({required this.data});
  factory _DriverProfileEnvelope.fromJson(Map<String, dynamic> json) => _$DriverProfileEnvelopeFromJson(json);

@override final  DriverProfile data;

/// Create a copy of DriverProfileEnvelope
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DriverProfileEnvelopeCopyWith<_DriverProfileEnvelope> get copyWith => __$DriverProfileEnvelopeCopyWithImpl<_DriverProfileEnvelope>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DriverProfileEnvelopeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DriverProfileEnvelope&&(identical(other.data, data) || other.data == data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,data);

@override
String toString() {
  return 'DriverProfileEnvelope(data: $data)';
}


}

/// @nodoc
abstract mixin class _$DriverProfileEnvelopeCopyWith<$Res> implements $DriverProfileEnvelopeCopyWith<$Res> {
  factory _$DriverProfileEnvelopeCopyWith(_DriverProfileEnvelope value, $Res Function(_DriverProfileEnvelope) _then) = __$DriverProfileEnvelopeCopyWithImpl;
@override @useResult
$Res call({
 DriverProfile data
});


@override $DriverProfileCopyWith<$Res> get data;

}
/// @nodoc
class __$DriverProfileEnvelopeCopyWithImpl<$Res>
    implements _$DriverProfileEnvelopeCopyWith<$Res> {
  __$DriverProfileEnvelopeCopyWithImpl(this._self, this._then);

  final _DriverProfileEnvelope _self;
  final $Res Function(_DriverProfileEnvelope) _then;

/// Create a copy of DriverProfileEnvelope
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? data = null,}) {
  return _then(_DriverProfileEnvelope(
data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as DriverProfile,
  ));
}

/// Create a copy of DriverProfileEnvelope
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DriverProfileCopyWith<$Res> get data {
  
  return $DriverProfileCopyWith<$Res>(_self.data, (value) {
    return _then(_self.copyWith(data: value));
  });
}
}

// dart format on
