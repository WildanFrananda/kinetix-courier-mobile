// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'driver_session.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DriverSession {

@JsonKey(name: 'driver_id')@DriverIdConverter() DriverId get driverId; String get token;@JsonKey(name: 'refresh_token') String get refreshToken;
/// Create a copy of DriverSession
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DriverSessionCopyWith<DriverSession> get copyWith => _$DriverSessionCopyWithImpl<DriverSession>(this as DriverSession, _$identity);

  /// Serializes this DriverSession to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DriverSession&&(identical(other.driverId, driverId) || other.driverId == driverId)&&(identical(other.token, token) || other.token == token)&&(identical(other.refreshToken, refreshToken) || other.refreshToken == refreshToken));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,driverId,token,refreshToken);

@override
String toString() {
  return 'DriverSession(driverId: $driverId, token: $token, refreshToken: $refreshToken)';
}


}

/// @nodoc
abstract mixin class $DriverSessionCopyWith<$Res>  {
  factory $DriverSessionCopyWith(DriverSession value, $Res Function(DriverSession) _then) = _$DriverSessionCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'driver_id')@DriverIdConverter() DriverId driverId, String token,@JsonKey(name: 'refresh_token') String refreshToken
});




}
/// @nodoc
class _$DriverSessionCopyWithImpl<$Res>
    implements $DriverSessionCopyWith<$Res> {
  _$DriverSessionCopyWithImpl(this._self, this._then);

  final DriverSession _self;
  final $Res Function(DriverSession) _then;

/// Create a copy of DriverSession
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? driverId = null,Object? token = null,Object? refreshToken = null,}) {
  return _then(_self.copyWith(
driverId: null == driverId ? _self.driverId : driverId // ignore: cast_nullable_to_non_nullable
as DriverId,token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,refreshToken: null == refreshToken ? _self.refreshToken : refreshToken // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [DriverSession].
extension DriverSessionPatterns on DriverSession {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DriverSession value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DriverSession() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DriverSession value)  $default,){
final _that = this;
switch (_that) {
case _DriverSession():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DriverSession value)?  $default,){
final _that = this;
switch (_that) {
case _DriverSession() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'driver_id')@DriverIdConverter()  DriverId driverId,  String token, @JsonKey(name: 'refresh_token')  String refreshToken)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DriverSession() when $default != null:
return $default(_that.driverId,_that.token,_that.refreshToken);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'driver_id')@DriverIdConverter()  DriverId driverId,  String token, @JsonKey(name: 'refresh_token')  String refreshToken)  $default,) {final _that = this;
switch (_that) {
case _DriverSession():
return $default(_that.driverId,_that.token,_that.refreshToken);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'driver_id')@DriverIdConverter()  DriverId driverId,  String token, @JsonKey(name: 'refresh_token')  String refreshToken)?  $default,) {final _that = this;
switch (_that) {
case _DriverSession() when $default != null:
return $default(_that.driverId,_that.token,_that.refreshToken);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DriverSession implements DriverSession {
  const _DriverSession({@JsonKey(name: 'driver_id')@DriverIdConverter() required this.driverId, required this.token, @JsonKey(name: 'refresh_token') required this.refreshToken});
  factory _DriverSession.fromJson(Map<String, dynamic> json) => _$DriverSessionFromJson(json);

@override@JsonKey(name: 'driver_id')@DriverIdConverter() final  DriverId driverId;
@override final  String token;
@override@JsonKey(name: 'refresh_token') final  String refreshToken;

/// Create a copy of DriverSession
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DriverSessionCopyWith<_DriverSession> get copyWith => __$DriverSessionCopyWithImpl<_DriverSession>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DriverSessionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DriverSession&&(identical(other.driverId, driverId) || other.driverId == driverId)&&(identical(other.token, token) || other.token == token)&&(identical(other.refreshToken, refreshToken) || other.refreshToken == refreshToken));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,driverId,token,refreshToken);

@override
String toString() {
  return 'DriverSession(driverId: $driverId, token: $token, refreshToken: $refreshToken)';
}


}

/// @nodoc
abstract mixin class _$DriverSessionCopyWith<$Res> implements $DriverSessionCopyWith<$Res> {
  factory _$DriverSessionCopyWith(_DriverSession value, $Res Function(_DriverSession) _then) = __$DriverSessionCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'driver_id')@DriverIdConverter() DriverId driverId, String token,@JsonKey(name: 'refresh_token') String refreshToken
});




}
/// @nodoc
class __$DriverSessionCopyWithImpl<$Res>
    implements _$DriverSessionCopyWith<$Res> {
  __$DriverSessionCopyWithImpl(this._self, this._then);

  final _DriverSession _self;
  final $Res Function(_DriverSession) _then;

/// Create a copy of DriverSession
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? driverId = null,Object? token = null,Object? refreshToken = null,}) {
  return _then(_DriverSession(
driverId: null == driverId ? _self.driverId : driverId // ignore: cast_nullable_to_non_nullable
as DriverId,token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,refreshToken: null == refreshToken ? _self.refreshToken : refreshToken // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
