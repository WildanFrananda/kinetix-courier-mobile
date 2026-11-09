// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'two_factor_challenge.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TwoFactorChallenge {

 String get challengeToken; int get expiresIn;
/// Create a copy of TwoFactorChallenge
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TwoFactorChallengeCopyWith<TwoFactorChallenge> get copyWith => _$TwoFactorChallengeCopyWithImpl<TwoFactorChallenge>(this as TwoFactorChallenge, _$identity);

  /// Serializes this TwoFactorChallenge to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TwoFactorChallenge&&(identical(other.challengeToken, challengeToken) || other.challengeToken == challengeToken)&&(identical(other.expiresIn, expiresIn) || other.expiresIn == expiresIn));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,challengeToken,expiresIn);

@override
String toString() {
  return 'TwoFactorChallenge(challengeToken: $challengeToken, expiresIn: $expiresIn)';
}


}

/// @nodoc
abstract mixin class $TwoFactorChallengeCopyWith<$Res>  {
  factory $TwoFactorChallengeCopyWith(TwoFactorChallenge value, $Res Function(TwoFactorChallenge) _then) = _$TwoFactorChallengeCopyWithImpl;
@useResult
$Res call({
 String challengeToken, int expiresIn
});




}
/// @nodoc
class _$TwoFactorChallengeCopyWithImpl<$Res>
    implements $TwoFactorChallengeCopyWith<$Res> {
  _$TwoFactorChallengeCopyWithImpl(this._self, this._then);

  final TwoFactorChallenge _self;
  final $Res Function(TwoFactorChallenge) _then;

/// Create a copy of TwoFactorChallenge
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? challengeToken = null,Object? expiresIn = null,}) {
  return _then(_self.copyWith(
challengeToken: null == challengeToken ? _self.challengeToken : challengeToken // ignore: cast_nullable_to_non_nullable
as String,expiresIn: null == expiresIn ? _self.expiresIn : expiresIn // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [TwoFactorChallenge].
extension TwoFactorChallengePatterns on TwoFactorChallenge {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TwoFactorChallenge value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TwoFactorChallenge() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TwoFactorChallenge value)  $default,){
final _that = this;
switch (_that) {
case _TwoFactorChallenge():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TwoFactorChallenge value)?  $default,){
final _that = this;
switch (_that) {
case _TwoFactorChallenge() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String challengeToken,  int expiresIn)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TwoFactorChallenge() when $default != null:
return $default(_that.challengeToken,_that.expiresIn);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String challengeToken,  int expiresIn)  $default,) {final _that = this;
switch (_that) {
case _TwoFactorChallenge():
return $default(_that.challengeToken,_that.expiresIn);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String challengeToken,  int expiresIn)?  $default,) {final _that = this;
switch (_that) {
case _TwoFactorChallenge() when $default != null:
return $default(_that.challengeToken,_that.expiresIn);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TwoFactorChallenge implements TwoFactorChallenge {
  const _TwoFactorChallenge({required this.challengeToken, required this.expiresIn});
  factory _TwoFactorChallenge.fromJson(Map<String, dynamic> json) => _$TwoFactorChallengeFromJson(json);

@override final  String challengeToken;
@override final  int expiresIn;

/// Create a copy of TwoFactorChallenge
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TwoFactorChallengeCopyWith<_TwoFactorChallenge> get copyWith => __$TwoFactorChallengeCopyWithImpl<_TwoFactorChallenge>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TwoFactorChallengeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TwoFactorChallenge&&(identical(other.challengeToken, challengeToken) || other.challengeToken == challengeToken)&&(identical(other.expiresIn, expiresIn) || other.expiresIn == expiresIn));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,challengeToken,expiresIn);

@override
String toString() {
  return 'TwoFactorChallenge(challengeToken: $challengeToken, expiresIn: $expiresIn)';
}


}

/// @nodoc
abstract mixin class _$TwoFactorChallengeCopyWith<$Res> implements $TwoFactorChallengeCopyWith<$Res> {
  factory _$TwoFactorChallengeCopyWith(_TwoFactorChallenge value, $Res Function(_TwoFactorChallenge) _then) = __$TwoFactorChallengeCopyWithImpl;
@override @useResult
$Res call({
 String challengeToken, int expiresIn
});




}
/// @nodoc
class __$TwoFactorChallengeCopyWithImpl<$Res>
    implements _$TwoFactorChallengeCopyWith<$Res> {
  __$TwoFactorChallengeCopyWithImpl(this._self, this._then);

  final _TwoFactorChallenge _self;
  final $Res Function(_TwoFactorChallenge) _then;

/// Create a copy of TwoFactorChallenge
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? challengeToken = null,Object? expiresIn = null,}) {
  return _then(_TwoFactorChallenge(
challengeToken: null == challengeToken ? _self.challengeToken : challengeToken // ignore: cast_nullable_to_non_nullable
as String,expiresIn: null == expiresIn ? _self.expiresIn : expiresIn // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
