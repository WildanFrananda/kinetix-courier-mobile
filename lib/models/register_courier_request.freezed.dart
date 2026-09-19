// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'register_courier_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RegisterCourierRequest {

 String get email; String get password; String get fullName; String get phoneNumber; String get vehiclePlate; int get capacityKg;
/// Create a copy of RegisterCourierRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RegisterCourierRequestCopyWith<RegisterCourierRequest> get copyWith => _$RegisterCourierRequestCopyWithImpl<RegisterCourierRequest>(this as RegisterCourierRequest, _$identity);

  /// Serializes this RegisterCourierRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RegisterCourierRequest&&(identical(other.email, email) || other.email == email)&&(identical(other.password, password) || other.password == password)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.phoneNumber, phoneNumber) || other.phoneNumber == phoneNumber)&&(identical(other.vehiclePlate, vehiclePlate) || other.vehiclePlate == vehiclePlate)&&(identical(other.capacityKg, capacityKg) || other.capacityKg == capacityKg));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,email,password,fullName,phoneNumber,vehiclePlate,capacityKg);

@override
String toString() {
  return 'RegisterCourierRequest(email: $email, password: $password, fullName: $fullName, phoneNumber: $phoneNumber, vehiclePlate: $vehiclePlate, capacityKg: $capacityKg)';
}


}

/// @nodoc
abstract mixin class $RegisterCourierRequestCopyWith<$Res>  {
  factory $RegisterCourierRequestCopyWith(RegisterCourierRequest value, $Res Function(RegisterCourierRequest) _then) = _$RegisterCourierRequestCopyWithImpl;
@useResult
$Res call({
 String email, String password, String fullName, String phoneNumber, String vehiclePlate, int capacityKg
});




}
/// @nodoc
class _$RegisterCourierRequestCopyWithImpl<$Res>
    implements $RegisterCourierRequestCopyWith<$Res> {
  _$RegisterCourierRequestCopyWithImpl(this._self, this._then);

  final RegisterCourierRequest _self;
  final $Res Function(RegisterCourierRequest) _then;

/// Create a copy of RegisterCourierRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? email = null,Object? password = null,Object? fullName = null,Object? phoneNumber = null,Object? vehiclePlate = null,Object? capacityKg = null,}) {
  return _then(_self.copyWith(
email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,password: null == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,phoneNumber: null == phoneNumber ? _self.phoneNumber : phoneNumber // ignore: cast_nullable_to_non_nullable
as String,vehiclePlate: null == vehiclePlate ? _self.vehiclePlate : vehiclePlate // ignore: cast_nullable_to_non_nullable
as String,capacityKg: null == capacityKg ? _self.capacityKg : capacityKg // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [RegisterCourierRequest].
extension RegisterCourierRequestPatterns on RegisterCourierRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RegisterCourierRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RegisterCourierRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RegisterCourierRequest value)  $default,){
final _that = this;
switch (_that) {
case _RegisterCourierRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RegisterCourierRequest value)?  $default,){
final _that = this;
switch (_that) {
case _RegisterCourierRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String email,  String password,  String fullName,  String phoneNumber,  String vehiclePlate,  int capacityKg)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RegisterCourierRequest() when $default != null:
return $default(_that.email,_that.password,_that.fullName,_that.phoneNumber,_that.vehiclePlate,_that.capacityKg);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String email,  String password,  String fullName,  String phoneNumber,  String vehiclePlate,  int capacityKg)  $default,) {final _that = this;
switch (_that) {
case _RegisterCourierRequest():
return $default(_that.email,_that.password,_that.fullName,_that.phoneNumber,_that.vehiclePlate,_that.capacityKg);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String email,  String password,  String fullName,  String phoneNumber,  String vehiclePlate,  int capacityKg)?  $default,) {final _that = this;
switch (_that) {
case _RegisterCourierRequest() when $default != null:
return $default(_that.email,_that.password,_that.fullName,_that.phoneNumber,_that.vehiclePlate,_that.capacityKg);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RegisterCourierRequest implements RegisterCourierRequest {
  const _RegisterCourierRequest({required this.email, required this.password, required this.fullName, required this.phoneNumber, required this.vehiclePlate, required this.capacityKg});
  factory _RegisterCourierRequest.fromJson(Map<String, dynamic> json) => _$RegisterCourierRequestFromJson(json);

@override final  String email;
@override final  String password;
@override final  String fullName;
@override final  String phoneNumber;
@override final  String vehiclePlate;
@override final  int capacityKg;

/// Create a copy of RegisterCourierRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RegisterCourierRequestCopyWith<_RegisterCourierRequest> get copyWith => __$RegisterCourierRequestCopyWithImpl<_RegisterCourierRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RegisterCourierRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RegisterCourierRequest&&(identical(other.email, email) || other.email == email)&&(identical(other.password, password) || other.password == password)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.phoneNumber, phoneNumber) || other.phoneNumber == phoneNumber)&&(identical(other.vehiclePlate, vehiclePlate) || other.vehiclePlate == vehiclePlate)&&(identical(other.capacityKg, capacityKg) || other.capacityKg == capacityKg));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,email,password,fullName,phoneNumber,vehiclePlate,capacityKg);

@override
String toString() {
  return 'RegisterCourierRequest(email: $email, password: $password, fullName: $fullName, phoneNumber: $phoneNumber, vehiclePlate: $vehiclePlate, capacityKg: $capacityKg)';
}


}

/// @nodoc
abstract mixin class _$RegisterCourierRequestCopyWith<$Res> implements $RegisterCourierRequestCopyWith<$Res> {
  factory _$RegisterCourierRequestCopyWith(_RegisterCourierRequest value, $Res Function(_RegisterCourierRequest) _then) = __$RegisterCourierRequestCopyWithImpl;
@override @useResult
$Res call({
 String email, String password, String fullName, String phoneNumber, String vehiclePlate, int capacityKg
});




}
/// @nodoc
class __$RegisterCourierRequestCopyWithImpl<$Res>
    implements _$RegisterCourierRequestCopyWith<$Res> {
  __$RegisterCourierRequestCopyWithImpl(this._self, this._then);

  final _RegisterCourierRequest _self;
  final $Res Function(_RegisterCourierRequest) _then;

/// Create a copy of RegisterCourierRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? email = null,Object? password = null,Object? fullName = null,Object? phoneNumber = null,Object? vehiclePlate = null,Object? capacityKg = null,}) {
  return _then(_RegisterCourierRequest(
email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,password: null == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,phoneNumber: null == phoneNumber ? _self.phoneNumber : phoneNumber // ignore: cast_nullable_to_non_nullable
as String,vehiclePlate: null == vehiclePlate ? _self.vehiclePlate : vehiclePlate // ignore: cast_nullable_to_non_nullable
as String,capacityKg: null == capacityKg ? _self.capacityKg : capacityKg // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
