// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'presentation_offer.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PresentationOffer {

 String get contractAddress; String get predicateId; String get challenge; Uri get answerUrl; String get label; int get deliveries; int get ratingHundredths; int get daysActive; String get issuedSince;
/// Create a copy of PresentationOffer
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PresentationOfferCopyWith<PresentationOffer> get copyWith => _$PresentationOfferCopyWithImpl<PresentationOffer>(this as PresentationOffer, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PresentationOffer&&(identical(other.contractAddress, contractAddress) || other.contractAddress == contractAddress)&&(identical(other.predicateId, predicateId) || other.predicateId == predicateId)&&(identical(other.challenge, challenge) || other.challenge == challenge)&&(identical(other.answerUrl, answerUrl) || other.answerUrl == answerUrl)&&(identical(other.label, label) || other.label == label)&&(identical(other.deliveries, deliveries) || other.deliveries == deliveries)&&(identical(other.ratingHundredths, ratingHundredths) || other.ratingHundredths == ratingHundredths)&&(identical(other.daysActive, daysActive) || other.daysActive == daysActive)&&(identical(other.issuedSince, issuedSince) || other.issuedSince == issuedSince));
}


@override
int get hashCode => Object.hash(runtimeType,contractAddress,predicateId,challenge,answerUrl,label,deliveries,ratingHundredths,daysActive,issuedSince);

@override
String toString() {
  return 'PresentationOffer(contractAddress: $contractAddress, predicateId: $predicateId, challenge: $challenge, answerUrl: $answerUrl, label: $label, deliveries: $deliveries, ratingHundredths: $ratingHundredths, daysActive: $daysActive, issuedSince: $issuedSince)';
}


}

/// @nodoc
abstract mixin class $PresentationOfferCopyWith<$Res>  {
  factory $PresentationOfferCopyWith(PresentationOffer value, $Res Function(PresentationOffer) _then) = _$PresentationOfferCopyWithImpl;
@useResult
$Res call({
 String contractAddress, String predicateId, String challenge, Uri answerUrl, String label, int deliveries, int ratingHundredths, int daysActive, String issuedSince
});




}
/// @nodoc
class _$PresentationOfferCopyWithImpl<$Res>
    implements $PresentationOfferCopyWith<$Res> {
  _$PresentationOfferCopyWithImpl(this._self, this._then);

  final PresentationOffer _self;
  final $Res Function(PresentationOffer) _then;

/// Create a copy of PresentationOffer
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? contractAddress = null,Object? predicateId = null,Object? challenge = null,Object? answerUrl = null,Object? label = null,Object? deliveries = null,Object? ratingHundredths = null,Object? daysActive = null,Object? issuedSince = null,}) {
  return _then(_self.copyWith(
contractAddress: null == contractAddress ? _self.contractAddress : contractAddress // ignore: cast_nullable_to_non_nullable
as String,predicateId: null == predicateId ? _self.predicateId : predicateId // ignore: cast_nullable_to_non_nullable
as String,challenge: null == challenge ? _self.challenge : challenge // ignore: cast_nullable_to_non_nullable
as String,answerUrl: null == answerUrl ? _self.answerUrl : answerUrl // ignore: cast_nullable_to_non_nullable
as Uri,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,deliveries: null == deliveries ? _self.deliveries : deliveries // ignore: cast_nullable_to_non_nullable
as int,ratingHundredths: null == ratingHundredths ? _self.ratingHundredths : ratingHundredths // ignore: cast_nullable_to_non_nullable
as int,daysActive: null == daysActive ? _self.daysActive : daysActive // ignore: cast_nullable_to_non_nullable
as int,issuedSince: null == issuedSince ? _self.issuedSince : issuedSince // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PresentationOffer].
extension PresentationOfferPatterns on PresentationOffer {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PresentationOffer value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PresentationOffer() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PresentationOffer value)  $default,){
final _that = this;
switch (_that) {
case _PresentationOffer():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PresentationOffer value)?  $default,){
final _that = this;
switch (_that) {
case _PresentationOffer() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String contractAddress,  String predicateId,  String challenge,  Uri answerUrl,  String label,  int deliveries,  int ratingHundredths,  int daysActive,  String issuedSince)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PresentationOffer() when $default != null:
return $default(_that.contractAddress,_that.predicateId,_that.challenge,_that.answerUrl,_that.label,_that.deliveries,_that.ratingHundredths,_that.daysActive,_that.issuedSince);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String contractAddress,  String predicateId,  String challenge,  Uri answerUrl,  String label,  int deliveries,  int ratingHundredths,  int daysActive,  String issuedSince)  $default,) {final _that = this;
switch (_that) {
case _PresentationOffer():
return $default(_that.contractAddress,_that.predicateId,_that.challenge,_that.answerUrl,_that.label,_that.deliveries,_that.ratingHundredths,_that.daysActive,_that.issuedSince);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String contractAddress,  String predicateId,  String challenge,  Uri answerUrl,  String label,  int deliveries,  int ratingHundredths,  int daysActive,  String issuedSince)?  $default,) {final _that = this;
switch (_that) {
case _PresentationOffer() when $default != null:
return $default(_that.contractAddress,_that.predicateId,_that.challenge,_that.answerUrl,_that.label,_that.deliveries,_that.ratingHundredths,_that.daysActive,_that.issuedSince);case _:
  return null;

}
}

}

/// @nodoc


class _PresentationOffer implements PresentationOffer {
  const _PresentationOffer({required this.contractAddress, required this.predicateId, required this.challenge, required this.answerUrl, required this.label, required this.deliveries, required this.ratingHundredths, required this.daysActive, required this.issuedSince});
  

@override final  String contractAddress;
@override final  String predicateId;
@override final  String challenge;
@override final  Uri answerUrl;
@override final  String label;
@override final  int deliveries;
@override final  int ratingHundredths;
@override final  int daysActive;
@override final  String issuedSince;

/// Create a copy of PresentationOffer
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PresentationOfferCopyWith<_PresentationOffer> get copyWith => __$PresentationOfferCopyWithImpl<_PresentationOffer>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PresentationOffer&&(identical(other.contractAddress, contractAddress) || other.contractAddress == contractAddress)&&(identical(other.predicateId, predicateId) || other.predicateId == predicateId)&&(identical(other.challenge, challenge) || other.challenge == challenge)&&(identical(other.answerUrl, answerUrl) || other.answerUrl == answerUrl)&&(identical(other.label, label) || other.label == label)&&(identical(other.deliveries, deliveries) || other.deliveries == deliveries)&&(identical(other.ratingHundredths, ratingHundredths) || other.ratingHundredths == ratingHundredths)&&(identical(other.daysActive, daysActive) || other.daysActive == daysActive)&&(identical(other.issuedSince, issuedSince) || other.issuedSince == issuedSince));
}


@override
int get hashCode => Object.hash(runtimeType,contractAddress,predicateId,challenge,answerUrl,label,deliveries,ratingHundredths,daysActive,issuedSince);

@override
String toString() {
  return 'PresentationOffer(contractAddress: $contractAddress, predicateId: $predicateId, challenge: $challenge, answerUrl: $answerUrl, label: $label, deliveries: $deliveries, ratingHundredths: $ratingHundredths, daysActive: $daysActive, issuedSince: $issuedSince)';
}


}

/// @nodoc
abstract mixin class _$PresentationOfferCopyWith<$Res> implements $PresentationOfferCopyWith<$Res> {
  factory _$PresentationOfferCopyWith(_PresentationOffer value, $Res Function(_PresentationOffer) _then) = __$PresentationOfferCopyWithImpl;
@override @useResult
$Res call({
 String contractAddress, String predicateId, String challenge, Uri answerUrl, String label, int deliveries, int ratingHundredths, int daysActive, String issuedSince
});




}
/// @nodoc
class __$PresentationOfferCopyWithImpl<$Res>
    implements _$PresentationOfferCopyWith<$Res> {
  __$PresentationOfferCopyWithImpl(this._self, this._then);

  final _PresentationOffer _self;
  final $Res Function(_PresentationOffer) _then;

/// Create a copy of PresentationOffer
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? contractAddress = null,Object? predicateId = null,Object? challenge = null,Object? answerUrl = null,Object? label = null,Object? deliveries = null,Object? ratingHundredths = null,Object? daysActive = null,Object? issuedSince = null,}) {
  return _then(_PresentationOffer(
contractAddress: null == contractAddress ? _self.contractAddress : contractAddress // ignore: cast_nullable_to_non_nullable
as String,predicateId: null == predicateId ? _self.predicateId : predicateId // ignore: cast_nullable_to_non_nullable
as String,challenge: null == challenge ? _self.challenge : challenge // ignore: cast_nullable_to_non_nullable
as String,answerUrl: null == answerUrl ? _self.answerUrl : answerUrl // ignore: cast_nullable_to_non_nullable
as Uri,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,deliveries: null == deliveries ? _self.deliveries : deliveries // ignore: cast_nullable_to_non_nullable
as int,ratingHundredths: null == ratingHundredths ? _self.ratingHundredths : ratingHundredths // ignore: cast_nullable_to_non_nullable
as int,daysActive: null == daysActive ? _self.daysActive : daysActive // ignore: cast_nullable_to_non_nullable
as int,issuedSince: null == issuedSince ? _self.issuedSince : issuedSince // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
