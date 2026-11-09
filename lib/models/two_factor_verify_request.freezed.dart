// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'two_factor_verify_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TwoFactorVerifyRequest {

 String get challengeToken; String get code;
/// Create a copy of TwoFactorVerifyRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TwoFactorVerifyRequestCopyWith<TwoFactorVerifyRequest> get copyWith => _$TwoFactorVerifyRequestCopyWithImpl<TwoFactorVerifyRequest>(this as TwoFactorVerifyRequest, _$identity);

  /// Serializes this TwoFactorVerifyRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TwoFactorVerifyRequest&&(identical(other.challengeToken, challengeToken) || other.challengeToken == challengeToken)&&(identical(other.code, code) || other.code == code));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,challengeToken,code);

@override
String toString() {
  return 'TwoFactorVerifyRequest(challengeToken: $challengeToken, code: $code)';
}


}

/// @nodoc
abstract mixin class $TwoFactorVerifyRequestCopyWith<$Res>  {
  factory $TwoFactorVerifyRequestCopyWith(TwoFactorVerifyRequest value, $Res Function(TwoFactorVerifyRequest) _then) = _$TwoFactorVerifyRequestCopyWithImpl;
@useResult
$Res call({
 String challengeToken, String code
});




}
/// @nodoc
class _$TwoFactorVerifyRequestCopyWithImpl<$Res>
    implements $TwoFactorVerifyRequestCopyWith<$Res> {
  _$TwoFactorVerifyRequestCopyWithImpl(this._self, this._then);

  final TwoFactorVerifyRequest _self;
  final $Res Function(TwoFactorVerifyRequest) _then;

/// Create a copy of TwoFactorVerifyRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? challengeToken = null,Object? code = null,}) {
  return _then(_self.copyWith(
challengeToken: null == challengeToken ? _self.challengeToken : challengeToken // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [TwoFactorVerifyRequest].
extension TwoFactorVerifyRequestPatterns on TwoFactorVerifyRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TwoFactorVerifyRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TwoFactorVerifyRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TwoFactorVerifyRequest value)  $default,){
final _that = this;
switch (_that) {
case _TwoFactorVerifyRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TwoFactorVerifyRequest value)?  $default,){
final _that = this;
switch (_that) {
case _TwoFactorVerifyRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String challengeToken,  String code)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TwoFactorVerifyRequest() when $default != null:
return $default(_that.challengeToken,_that.code);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String challengeToken,  String code)  $default,) {final _that = this;
switch (_that) {
case _TwoFactorVerifyRequest():
return $default(_that.challengeToken,_that.code);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String challengeToken,  String code)?  $default,) {final _that = this;
switch (_that) {
case _TwoFactorVerifyRequest() when $default != null:
return $default(_that.challengeToken,_that.code);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TwoFactorVerifyRequest implements TwoFactorVerifyRequest {
  const _TwoFactorVerifyRequest({required this.challengeToken, required this.code});
  factory _TwoFactorVerifyRequest.fromJson(Map<String, dynamic> json) => _$TwoFactorVerifyRequestFromJson(json);

@override final  String challengeToken;
@override final  String code;

/// Create a copy of TwoFactorVerifyRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TwoFactorVerifyRequestCopyWith<_TwoFactorVerifyRequest> get copyWith => __$TwoFactorVerifyRequestCopyWithImpl<_TwoFactorVerifyRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TwoFactorVerifyRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TwoFactorVerifyRequest&&(identical(other.challengeToken, challengeToken) || other.challengeToken == challengeToken)&&(identical(other.code, code) || other.code == code));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,challengeToken,code);

@override
String toString() {
  return 'TwoFactorVerifyRequest(challengeToken: $challengeToken, code: $code)';
}


}

/// @nodoc
abstract mixin class _$TwoFactorVerifyRequestCopyWith<$Res> implements $TwoFactorVerifyRequestCopyWith<$Res> {
  factory _$TwoFactorVerifyRequestCopyWith(_TwoFactorVerifyRequest value, $Res Function(_TwoFactorVerifyRequest) _then) = __$TwoFactorVerifyRequestCopyWithImpl;
@override @useResult
$Res call({
 String challengeToken, String code
});




}
/// @nodoc
class __$TwoFactorVerifyRequestCopyWithImpl<$Res>
    implements _$TwoFactorVerifyRequestCopyWith<$Res> {
  __$TwoFactorVerifyRequestCopyWithImpl(this._self, this._then);

  final _TwoFactorVerifyRequest _self;
  final $Res Function(_TwoFactorVerifyRequest) _then;

/// Create a copy of TwoFactorVerifyRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? challengeToken = null,Object? code = null,}) {
  return _then(_TwoFactorVerifyRequest(
challengeToken: null == challengeToken ? _self.challengeToken : challengeToken // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
