// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'courier_credential.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CourierCredential {

 String get id; CredentialStanding get standing; int get issueDay; int get deliveries; int get ratingHundredths; int get daysActive; CredentialPlacement? get placement;
/// Create a copy of CourierCredential
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CourierCredentialCopyWith<CourierCredential> get copyWith => _$CourierCredentialCopyWithImpl<CourierCredential>(this as CourierCredential, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CourierCredential&&(identical(other.id, id) || other.id == id)&&(identical(other.standing, standing) || other.standing == standing)&&(identical(other.issueDay, issueDay) || other.issueDay == issueDay)&&(identical(other.deliveries, deliveries) || other.deliveries == deliveries)&&(identical(other.ratingHundredths, ratingHundredths) || other.ratingHundredths == ratingHundredths)&&(identical(other.daysActive, daysActive) || other.daysActive == daysActive)&&(identical(other.placement, placement) || other.placement == placement));
}


@override
int get hashCode => Object.hash(runtimeType,id,standing,issueDay,deliveries,ratingHundredths,daysActive,placement);

@override
String toString() {
  return 'CourierCredential(id: $id, standing: $standing, issueDay: $issueDay, deliveries: $deliveries, ratingHundredths: $ratingHundredths, daysActive: $daysActive, placement: $placement)';
}


}

/// @nodoc
abstract mixin class $CourierCredentialCopyWith<$Res>  {
  factory $CourierCredentialCopyWith(CourierCredential value, $Res Function(CourierCredential) _then) = _$CourierCredentialCopyWithImpl;
@useResult
$Res call({
 String id, CredentialStanding standing, int issueDay, int deliveries, int ratingHundredths, int daysActive, CredentialPlacement? placement
});


$CredentialPlacementCopyWith<$Res>? get placement;

}
/// @nodoc
class _$CourierCredentialCopyWithImpl<$Res>
    implements $CourierCredentialCopyWith<$Res> {
  _$CourierCredentialCopyWithImpl(this._self, this._then);

  final CourierCredential _self;
  final $Res Function(CourierCredential) _then;

/// Create a copy of CourierCredential
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? standing = null,Object? issueDay = null,Object? deliveries = null,Object? ratingHundredths = null,Object? daysActive = null,Object? placement = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,standing: null == standing ? _self.standing : standing // ignore: cast_nullable_to_non_nullable
as CredentialStanding,issueDay: null == issueDay ? _self.issueDay : issueDay // ignore: cast_nullable_to_non_nullable
as int,deliveries: null == deliveries ? _self.deliveries : deliveries // ignore: cast_nullable_to_non_nullable
as int,ratingHundredths: null == ratingHundredths ? _self.ratingHundredths : ratingHundredths // ignore: cast_nullable_to_non_nullable
as int,daysActive: null == daysActive ? _self.daysActive : daysActive // ignore: cast_nullable_to_non_nullable
as int,placement: freezed == placement ? _self.placement : placement // ignore: cast_nullable_to_non_nullable
as CredentialPlacement?,
  ));
}
/// Create a copy of CourierCredential
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CredentialPlacementCopyWith<$Res>? get placement {
    if (_self.placement == null) {
    return null;
  }

  return $CredentialPlacementCopyWith<$Res>(_self.placement!, (value) {
    return _then(_self.copyWith(placement: value));
  });
}
}


/// Adds pattern-matching-related methods to [CourierCredential].
extension CourierCredentialPatterns on CourierCredential {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CourierCredential value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CourierCredential() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CourierCredential value)  $default,){
final _that = this;
switch (_that) {
case _CourierCredential():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CourierCredential value)?  $default,){
final _that = this;
switch (_that) {
case _CourierCredential() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  CredentialStanding standing,  int issueDay,  int deliveries,  int ratingHundredths,  int daysActive,  CredentialPlacement? placement)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CourierCredential() when $default != null:
return $default(_that.id,_that.standing,_that.issueDay,_that.deliveries,_that.ratingHundredths,_that.daysActive,_that.placement);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  CredentialStanding standing,  int issueDay,  int deliveries,  int ratingHundredths,  int daysActive,  CredentialPlacement? placement)  $default,) {final _that = this;
switch (_that) {
case _CourierCredential():
return $default(_that.id,_that.standing,_that.issueDay,_that.deliveries,_that.ratingHundredths,_that.daysActive,_that.placement);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  CredentialStanding standing,  int issueDay,  int deliveries,  int ratingHundredths,  int daysActive,  CredentialPlacement? placement)?  $default,) {final _that = this;
switch (_that) {
case _CourierCredential() when $default != null:
return $default(_that.id,_that.standing,_that.issueDay,_that.deliveries,_that.ratingHundredths,_that.daysActive,_that.placement);case _:
  return null;

}
}

}

/// @nodoc


class _CourierCredential implements CourierCredential {
  const _CourierCredential({required this.id, required this.standing, required this.issueDay, required this.deliveries, required this.ratingHundredths, required this.daysActive, required this.placement});
  

@override final  String id;
@override final  CredentialStanding standing;
@override final  int issueDay;
@override final  int deliveries;
@override final  int ratingHundredths;
@override final  int daysActive;
@override final  CredentialPlacement? placement;

/// Create a copy of CourierCredential
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CourierCredentialCopyWith<_CourierCredential> get copyWith => __$CourierCredentialCopyWithImpl<_CourierCredential>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CourierCredential&&(identical(other.id, id) || other.id == id)&&(identical(other.standing, standing) || other.standing == standing)&&(identical(other.issueDay, issueDay) || other.issueDay == issueDay)&&(identical(other.deliveries, deliveries) || other.deliveries == deliveries)&&(identical(other.ratingHundredths, ratingHundredths) || other.ratingHundredths == ratingHundredths)&&(identical(other.daysActive, daysActive) || other.daysActive == daysActive)&&(identical(other.placement, placement) || other.placement == placement));
}


@override
int get hashCode => Object.hash(runtimeType,id,standing,issueDay,deliveries,ratingHundredths,daysActive,placement);

@override
String toString() {
  return 'CourierCredential(id: $id, standing: $standing, issueDay: $issueDay, deliveries: $deliveries, ratingHundredths: $ratingHundredths, daysActive: $daysActive, placement: $placement)';
}


}

/// @nodoc
abstract mixin class _$CourierCredentialCopyWith<$Res> implements $CourierCredentialCopyWith<$Res> {
  factory _$CourierCredentialCopyWith(_CourierCredential value, $Res Function(_CourierCredential) _then) = __$CourierCredentialCopyWithImpl;
@override @useResult
$Res call({
 String id, CredentialStanding standing, int issueDay, int deliveries, int ratingHundredths, int daysActive, CredentialPlacement? placement
});


@override $CredentialPlacementCopyWith<$Res>? get placement;

}
/// @nodoc
class __$CourierCredentialCopyWithImpl<$Res>
    implements _$CourierCredentialCopyWith<$Res> {
  __$CourierCredentialCopyWithImpl(this._self, this._then);

  final _CourierCredential _self;
  final $Res Function(_CourierCredential) _then;

/// Create a copy of CourierCredential
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? standing = null,Object? issueDay = null,Object? deliveries = null,Object? ratingHundredths = null,Object? daysActive = null,Object? placement = freezed,}) {
  return _then(_CourierCredential(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,standing: null == standing ? _self.standing : standing // ignore: cast_nullable_to_non_nullable
as CredentialStanding,issueDay: null == issueDay ? _self.issueDay : issueDay // ignore: cast_nullable_to_non_nullable
as int,deliveries: null == deliveries ? _self.deliveries : deliveries // ignore: cast_nullable_to_non_nullable
as int,ratingHundredths: null == ratingHundredths ? _self.ratingHundredths : ratingHundredths // ignore: cast_nullable_to_non_nullable
as int,daysActive: null == daysActive ? _self.daysActive : daysActive // ignore: cast_nullable_to_non_nullable
as int,placement: freezed == placement ? _self.placement : placement // ignore: cast_nullable_to_non_nullable
as CredentialPlacement?,
  ));
}

/// Create a copy of CourierCredential
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CredentialPlacementCopyWith<$Res>? get placement {
    if (_self.placement == null) {
    return null;
  }

  return $CredentialPlacementCopyWith<$Res>(_self.placement!, (value) {
    return _then(_self.copyWith(placement: value));
  });
}
}

// dart format on
