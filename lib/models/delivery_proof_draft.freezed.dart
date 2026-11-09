// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'delivery_proof_draft.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DeliveryProofDraft {

 String? get photoUrl; String? get signature;
/// Create a copy of DeliveryProofDraft
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeliveryProofDraftCopyWith<DeliveryProofDraft> get copyWith => _$DeliveryProofDraftCopyWithImpl<DeliveryProofDraft>(this as DeliveryProofDraft, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeliveryProofDraft&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl)&&(identical(other.signature, signature) || other.signature == signature));
}


@override
int get hashCode => Object.hash(runtimeType,photoUrl,signature);

@override
String toString() {
  return 'DeliveryProofDraft(photoUrl: $photoUrl, signature: $signature)';
}


}

/// @nodoc
abstract mixin class $DeliveryProofDraftCopyWith<$Res>  {
  factory $DeliveryProofDraftCopyWith(DeliveryProofDraft value, $Res Function(DeliveryProofDraft) _then) = _$DeliveryProofDraftCopyWithImpl;
@useResult
$Res call({
 String? photoUrl, String? signature
});




}
/// @nodoc
class _$DeliveryProofDraftCopyWithImpl<$Res>
    implements $DeliveryProofDraftCopyWith<$Res> {
  _$DeliveryProofDraftCopyWithImpl(this._self, this._then);

  final DeliveryProofDraft _self;
  final $Res Function(DeliveryProofDraft) _then;

/// Create a copy of DeliveryProofDraft
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? photoUrl = freezed,Object? signature = freezed,}) {
  return _then(_self.copyWith(
photoUrl: freezed == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String?,signature: freezed == signature ? _self.signature : signature // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [DeliveryProofDraft].
extension DeliveryProofDraftPatterns on DeliveryProofDraft {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DeliveryProofDraft value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DeliveryProofDraft() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DeliveryProofDraft value)  $default,){
final _that = this;
switch (_that) {
case _DeliveryProofDraft():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DeliveryProofDraft value)?  $default,){
final _that = this;
switch (_that) {
case _DeliveryProofDraft() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? photoUrl,  String? signature)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DeliveryProofDraft() when $default != null:
return $default(_that.photoUrl,_that.signature);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? photoUrl,  String? signature)  $default,) {final _that = this;
switch (_that) {
case _DeliveryProofDraft():
return $default(_that.photoUrl,_that.signature);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? photoUrl,  String? signature)?  $default,) {final _that = this;
switch (_that) {
case _DeliveryProofDraft() when $default != null:
return $default(_that.photoUrl,_that.signature);case _:
  return null;

}
}

}

/// @nodoc


class _DeliveryProofDraft implements DeliveryProofDraft {
  const _DeliveryProofDraft({this.photoUrl, this.signature});
  

@override final  String? photoUrl;
@override final  String? signature;

/// Create a copy of DeliveryProofDraft
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeliveryProofDraftCopyWith<_DeliveryProofDraft> get copyWith => __$DeliveryProofDraftCopyWithImpl<_DeliveryProofDraft>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeliveryProofDraft&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl)&&(identical(other.signature, signature) || other.signature == signature));
}


@override
int get hashCode => Object.hash(runtimeType,photoUrl,signature);

@override
String toString() {
  return 'DeliveryProofDraft(photoUrl: $photoUrl, signature: $signature)';
}


}

/// @nodoc
abstract mixin class _$DeliveryProofDraftCopyWith<$Res> implements $DeliveryProofDraftCopyWith<$Res> {
  factory _$DeliveryProofDraftCopyWith(_DeliveryProofDraft value, $Res Function(_DeliveryProofDraft) _then) = __$DeliveryProofDraftCopyWithImpl;
@override @useResult
$Res call({
 String? photoUrl, String? signature
});




}
/// @nodoc
class __$DeliveryProofDraftCopyWithImpl<$Res>
    implements _$DeliveryProofDraftCopyWith<$Res> {
  __$DeliveryProofDraftCopyWithImpl(this._self, this._then);

  final _DeliveryProofDraft _self;
  final $Res Function(_DeliveryProofDraft) _then;

/// Create a copy of DeliveryProofDraft
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? photoUrl = freezed,Object? signature = freezed,}) {
  return _then(_DeliveryProofDraft(
photoUrl: freezed == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String?,signature: freezed == signature ? _self.signature : signature // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
