// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'courier_registration_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CourierRegistrationResponse {

 String get accessToken; String get refreshToken; int get expiresIn; String get tokenType; AuthenticatedAccount get user;@DriverIdConverter() DriverId get driverId;
/// Create a copy of CourierRegistrationResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CourierRegistrationResponseCopyWith<CourierRegistrationResponse> get copyWith => _$CourierRegistrationResponseCopyWithImpl<CourierRegistrationResponse>(this as CourierRegistrationResponse, _$identity);

  /// Serializes this CourierRegistrationResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CourierRegistrationResponse&&(identical(other.accessToken, accessToken) || other.accessToken == accessToken)&&(identical(other.refreshToken, refreshToken) || other.refreshToken == refreshToken)&&(identical(other.expiresIn, expiresIn) || other.expiresIn == expiresIn)&&(identical(other.tokenType, tokenType) || other.tokenType == tokenType)&&(identical(other.user, user) || other.user == user)&&(identical(other.driverId, driverId) || other.driverId == driverId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,accessToken,refreshToken,expiresIn,tokenType,user,driverId);

@override
String toString() {
  return 'CourierRegistrationResponse(accessToken: $accessToken, refreshToken: $refreshToken, expiresIn: $expiresIn, tokenType: $tokenType, user: $user, driverId: $driverId)';
}


}

/// @nodoc
abstract mixin class $CourierRegistrationResponseCopyWith<$Res>  {
  factory $CourierRegistrationResponseCopyWith(CourierRegistrationResponse value, $Res Function(CourierRegistrationResponse) _then) = _$CourierRegistrationResponseCopyWithImpl;
@useResult
$Res call({
 String accessToken, String refreshToken, int expiresIn, String tokenType, AuthenticatedAccount user,@DriverIdConverter() DriverId driverId
});


$AuthenticatedAccountCopyWith<$Res> get user;

}
/// @nodoc
class _$CourierRegistrationResponseCopyWithImpl<$Res>
    implements $CourierRegistrationResponseCopyWith<$Res> {
  _$CourierRegistrationResponseCopyWithImpl(this._self, this._then);

  final CourierRegistrationResponse _self;
  final $Res Function(CourierRegistrationResponse) _then;

/// Create a copy of CourierRegistrationResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? accessToken = null,Object? refreshToken = null,Object? expiresIn = null,Object? tokenType = null,Object? user = null,Object? driverId = null,}) {
  return _then(_self.copyWith(
accessToken: null == accessToken ? _self.accessToken : accessToken // ignore: cast_nullable_to_non_nullable
as String,refreshToken: null == refreshToken ? _self.refreshToken : refreshToken // ignore: cast_nullable_to_non_nullable
as String,expiresIn: null == expiresIn ? _self.expiresIn : expiresIn // ignore: cast_nullable_to_non_nullable
as int,tokenType: null == tokenType ? _self.tokenType : tokenType // ignore: cast_nullable_to_non_nullable
as String,user: null == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as AuthenticatedAccount,driverId: null == driverId ? _self.driverId : driverId // ignore: cast_nullable_to_non_nullable
as DriverId,
  ));
}
/// Create a copy of CourierRegistrationResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthenticatedAccountCopyWith<$Res> get user {
  
  return $AuthenticatedAccountCopyWith<$Res>(_self.user, (value) {
    return _then(_self.copyWith(user: value));
  });
}
}


/// Adds pattern-matching-related methods to [CourierRegistrationResponse].
extension CourierRegistrationResponsePatterns on CourierRegistrationResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CourierRegistrationResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CourierRegistrationResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CourierRegistrationResponse value)  $default,){
final _that = this;
switch (_that) {
case _CourierRegistrationResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CourierRegistrationResponse value)?  $default,){
final _that = this;
switch (_that) {
case _CourierRegistrationResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String accessToken,  String refreshToken,  int expiresIn,  String tokenType,  AuthenticatedAccount user, @DriverIdConverter()  DriverId driverId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CourierRegistrationResponse() when $default != null:
return $default(_that.accessToken,_that.refreshToken,_that.expiresIn,_that.tokenType,_that.user,_that.driverId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String accessToken,  String refreshToken,  int expiresIn,  String tokenType,  AuthenticatedAccount user, @DriverIdConverter()  DriverId driverId)  $default,) {final _that = this;
switch (_that) {
case _CourierRegistrationResponse():
return $default(_that.accessToken,_that.refreshToken,_that.expiresIn,_that.tokenType,_that.user,_that.driverId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String accessToken,  String refreshToken,  int expiresIn,  String tokenType,  AuthenticatedAccount user, @DriverIdConverter()  DriverId driverId)?  $default,) {final _that = this;
switch (_that) {
case _CourierRegistrationResponse() when $default != null:
return $default(_that.accessToken,_that.refreshToken,_that.expiresIn,_that.tokenType,_that.user,_that.driverId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CourierRegistrationResponse implements CourierRegistrationResponse {
  const _CourierRegistrationResponse({required this.accessToken, required this.refreshToken, required this.expiresIn, required this.tokenType, required this.user, @DriverIdConverter() required this.driverId});
  factory _CourierRegistrationResponse.fromJson(Map<String, dynamic> json) => _$CourierRegistrationResponseFromJson(json);

@override final  String accessToken;
@override final  String refreshToken;
@override final  int expiresIn;
@override final  String tokenType;
@override final  AuthenticatedAccount user;
@override@DriverIdConverter() final  DriverId driverId;

/// Create a copy of CourierRegistrationResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CourierRegistrationResponseCopyWith<_CourierRegistrationResponse> get copyWith => __$CourierRegistrationResponseCopyWithImpl<_CourierRegistrationResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CourierRegistrationResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CourierRegistrationResponse&&(identical(other.accessToken, accessToken) || other.accessToken == accessToken)&&(identical(other.refreshToken, refreshToken) || other.refreshToken == refreshToken)&&(identical(other.expiresIn, expiresIn) || other.expiresIn == expiresIn)&&(identical(other.tokenType, tokenType) || other.tokenType == tokenType)&&(identical(other.user, user) || other.user == user)&&(identical(other.driverId, driverId) || other.driverId == driverId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,accessToken,refreshToken,expiresIn,tokenType,user,driverId);

@override
String toString() {
  return 'CourierRegistrationResponse(accessToken: $accessToken, refreshToken: $refreshToken, expiresIn: $expiresIn, tokenType: $tokenType, user: $user, driverId: $driverId)';
}


}

/// @nodoc
abstract mixin class _$CourierRegistrationResponseCopyWith<$Res> implements $CourierRegistrationResponseCopyWith<$Res> {
  factory _$CourierRegistrationResponseCopyWith(_CourierRegistrationResponse value, $Res Function(_CourierRegistrationResponse) _then) = __$CourierRegistrationResponseCopyWithImpl;
@override @useResult
$Res call({
 String accessToken, String refreshToken, int expiresIn, String tokenType, AuthenticatedAccount user,@DriverIdConverter() DriverId driverId
});


@override $AuthenticatedAccountCopyWith<$Res> get user;

}
/// @nodoc
class __$CourierRegistrationResponseCopyWithImpl<$Res>
    implements _$CourierRegistrationResponseCopyWith<$Res> {
  __$CourierRegistrationResponseCopyWithImpl(this._self, this._then);

  final _CourierRegistrationResponse _self;
  final $Res Function(_CourierRegistrationResponse) _then;

/// Create a copy of CourierRegistrationResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? accessToken = null,Object? refreshToken = null,Object? expiresIn = null,Object? tokenType = null,Object? user = null,Object? driverId = null,}) {
  return _then(_CourierRegistrationResponse(
accessToken: null == accessToken ? _self.accessToken : accessToken // ignore: cast_nullable_to_non_nullable
as String,refreshToken: null == refreshToken ? _self.refreshToken : refreshToken // ignore: cast_nullable_to_non_nullable
as String,expiresIn: null == expiresIn ? _self.expiresIn : expiresIn // ignore: cast_nullable_to_non_nullable
as int,tokenType: null == tokenType ? _self.tokenType : tokenType // ignore: cast_nullable_to_non_nullable
as String,user: null == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as AuthenticatedAccount,driverId: null == driverId ? _self.driverId : driverId // ignore: cast_nullable_to_non_nullable
as DriverId,
  ));
}

/// Create a copy of CourierRegistrationResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthenticatedAccountCopyWith<$Res> get user {
  
  return $AuthenticatedAccountCopyWith<$Res>(_self.user, (value) {
    return _then(_self.copyWith(user: value));
  });
}
}

// dart format on
