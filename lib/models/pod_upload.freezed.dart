// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pod_upload.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PodUpload {

@JsonKey(name: 'upload_url') String get uploadUrl;@JsonKey(name: 'photo_url') String get photoUrl;
/// Create a copy of PodUpload
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PodUploadCopyWith<PodUpload> get copyWith => _$PodUploadCopyWithImpl<PodUpload>(this as PodUpload, _$identity);

  /// Serializes this PodUpload to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PodUpload&&(identical(other.uploadUrl, uploadUrl) || other.uploadUrl == uploadUrl)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,uploadUrl,photoUrl);

@override
String toString() {
  return 'PodUpload(uploadUrl: $uploadUrl, photoUrl: $photoUrl)';
}


}

/// @nodoc
abstract mixin class $PodUploadCopyWith<$Res>  {
  factory $PodUploadCopyWith(PodUpload value, $Res Function(PodUpload) _then) = _$PodUploadCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'upload_url') String uploadUrl,@JsonKey(name: 'photo_url') String photoUrl
});




}
/// @nodoc
class _$PodUploadCopyWithImpl<$Res>
    implements $PodUploadCopyWith<$Res> {
  _$PodUploadCopyWithImpl(this._self, this._then);

  final PodUpload _self;
  final $Res Function(PodUpload) _then;

/// Create a copy of PodUpload
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? uploadUrl = null,Object? photoUrl = null,}) {
  return _then(_self.copyWith(
uploadUrl: null == uploadUrl ? _self.uploadUrl : uploadUrl // ignore: cast_nullable_to_non_nullable
as String,photoUrl: null == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PodUpload].
extension PodUploadPatterns on PodUpload {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PodUpload value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PodUpload() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PodUpload value)  $default,){
final _that = this;
switch (_that) {
case _PodUpload():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PodUpload value)?  $default,){
final _that = this;
switch (_that) {
case _PodUpload() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'upload_url')  String uploadUrl, @JsonKey(name: 'photo_url')  String photoUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PodUpload() when $default != null:
return $default(_that.uploadUrl,_that.photoUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'upload_url')  String uploadUrl, @JsonKey(name: 'photo_url')  String photoUrl)  $default,) {final _that = this;
switch (_that) {
case _PodUpload():
return $default(_that.uploadUrl,_that.photoUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'upload_url')  String uploadUrl, @JsonKey(name: 'photo_url')  String photoUrl)?  $default,) {final _that = this;
switch (_that) {
case _PodUpload() when $default != null:
return $default(_that.uploadUrl,_that.photoUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PodUpload implements PodUpload {
  const _PodUpload({@JsonKey(name: 'upload_url') required this.uploadUrl, @JsonKey(name: 'photo_url') required this.photoUrl});
  factory _PodUpload.fromJson(Map<String, dynamic> json) => _$PodUploadFromJson(json);

@override@JsonKey(name: 'upload_url') final  String uploadUrl;
@override@JsonKey(name: 'photo_url') final  String photoUrl;

/// Create a copy of PodUpload
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PodUploadCopyWith<_PodUpload> get copyWith => __$PodUploadCopyWithImpl<_PodUpload>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PodUploadToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PodUpload&&(identical(other.uploadUrl, uploadUrl) || other.uploadUrl == uploadUrl)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,uploadUrl,photoUrl);

@override
String toString() {
  return 'PodUpload(uploadUrl: $uploadUrl, photoUrl: $photoUrl)';
}


}

/// @nodoc
abstract mixin class _$PodUploadCopyWith<$Res> implements $PodUploadCopyWith<$Res> {
  factory _$PodUploadCopyWith(_PodUpload value, $Res Function(_PodUpload) _then) = __$PodUploadCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'upload_url') String uploadUrl,@JsonKey(name: 'photo_url') String photoUrl
});




}
/// @nodoc
class __$PodUploadCopyWithImpl<$Res>
    implements _$PodUploadCopyWith<$Res> {
  __$PodUploadCopyWithImpl(this._self, this._then);

  final _PodUpload _self;
  final $Res Function(_PodUpload) _then;

/// Create a copy of PodUpload
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? uploadUrl = null,Object? photoUrl = null,}) {
  return _then(_PodUpload(
uploadUrl: null == uploadUrl ? _self.uploadUrl : uploadUrl // ignore: cast_nullable_to_non_nullable
as String,photoUrl: null == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
