// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'credential_placement.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CredentialPlacement {

 int get generation; String get contractAddress; String get leafIndex;
/// Create a copy of CredentialPlacement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CredentialPlacementCopyWith<CredentialPlacement> get copyWith => _$CredentialPlacementCopyWithImpl<CredentialPlacement>(this as CredentialPlacement, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CredentialPlacement&&(identical(other.generation, generation) || other.generation == generation)&&(identical(other.contractAddress, contractAddress) || other.contractAddress == contractAddress)&&(identical(other.leafIndex, leafIndex) || other.leafIndex == leafIndex));
}


@override
int get hashCode => Object.hash(runtimeType,generation,contractAddress,leafIndex);

@override
String toString() {
  return 'CredentialPlacement(generation: $generation, contractAddress: $contractAddress, leafIndex: $leafIndex)';
}


}

/// @nodoc
abstract mixin class $CredentialPlacementCopyWith<$Res>  {
  factory $CredentialPlacementCopyWith(CredentialPlacement value, $Res Function(CredentialPlacement) _then) = _$CredentialPlacementCopyWithImpl;
@useResult
$Res call({
 int generation, String contractAddress, String leafIndex
});




}
/// @nodoc
class _$CredentialPlacementCopyWithImpl<$Res>
    implements $CredentialPlacementCopyWith<$Res> {
  _$CredentialPlacementCopyWithImpl(this._self, this._then);

  final CredentialPlacement _self;
  final $Res Function(CredentialPlacement) _then;

/// Create a copy of CredentialPlacement
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? generation = null,Object? contractAddress = null,Object? leafIndex = null,}) {
  return _then(_self.copyWith(
generation: null == generation ? _self.generation : generation // ignore: cast_nullable_to_non_nullable
as int,contractAddress: null == contractAddress ? _self.contractAddress : contractAddress // ignore: cast_nullable_to_non_nullable
as String,leafIndex: null == leafIndex ? _self.leafIndex : leafIndex // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [CredentialPlacement].
extension CredentialPlacementPatterns on CredentialPlacement {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CredentialPlacement value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CredentialPlacement() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CredentialPlacement value)  $default,){
final _that = this;
switch (_that) {
case _CredentialPlacement():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CredentialPlacement value)?  $default,){
final _that = this;
switch (_that) {
case _CredentialPlacement() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int generation,  String contractAddress,  String leafIndex)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CredentialPlacement() when $default != null:
return $default(_that.generation,_that.contractAddress,_that.leafIndex);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int generation,  String contractAddress,  String leafIndex)  $default,) {final _that = this;
switch (_that) {
case _CredentialPlacement():
return $default(_that.generation,_that.contractAddress,_that.leafIndex);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int generation,  String contractAddress,  String leafIndex)?  $default,) {final _that = this;
switch (_that) {
case _CredentialPlacement() when $default != null:
return $default(_that.generation,_that.contractAddress,_that.leafIndex);case _:
  return null;

}
}

}

/// @nodoc


class _CredentialPlacement implements CredentialPlacement {
  const _CredentialPlacement({required this.generation, required this.contractAddress, required this.leafIndex});
  

@override final  int generation;
@override final  String contractAddress;
@override final  String leafIndex;

/// Create a copy of CredentialPlacement
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CredentialPlacementCopyWith<_CredentialPlacement> get copyWith => __$CredentialPlacementCopyWithImpl<_CredentialPlacement>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CredentialPlacement&&(identical(other.generation, generation) || other.generation == generation)&&(identical(other.contractAddress, contractAddress) || other.contractAddress == contractAddress)&&(identical(other.leafIndex, leafIndex) || other.leafIndex == leafIndex));
}


@override
int get hashCode => Object.hash(runtimeType,generation,contractAddress,leafIndex);

@override
String toString() {
  return 'CredentialPlacement(generation: $generation, contractAddress: $contractAddress, leafIndex: $leafIndex)';
}


}

/// @nodoc
abstract mixin class _$CredentialPlacementCopyWith<$Res> implements $CredentialPlacementCopyWith<$Res> {
  factory _$CredentialPlacementCopyWith(_CredentialPlacement value, $Res Function(_CredentialPlacement) _then) = __$CredentialPlacementCopyWithImpl;
@override @useResult
$Res call({
 int generation, String contractAddress, String leafIndex
});




}
/// @nodoc
class __$CredentialPlacementCopyWithImpl<$Res>
    implements _$CredentialPlacementCopyWith<$Res> {
  __$CredentialPlacementCopyWithImpl(this._self, this._then);

  final _CredentialPlacement _self;
  final $Res Function(_CredentialPlacement) _then;

/// Create a copy of CredentialPlacement
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? generation = null,Object? contractAddress = null,Object? leafIndex = null,}) {
  return _then(_CredentialPlacement(
generation: null == generation ? _self.generation : generation // ignore: cast_nullable_to_non_nullable
as int,contractAddress: null == contractAddress ? _self.contractAddress : contractAddress // ignore: cast_nullable_to_non_nullable
as String,leafIndex: null == leafIndex ? _self.leafIndex : leafIndex // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
