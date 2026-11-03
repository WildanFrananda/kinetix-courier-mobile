// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'presented_answer.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PresentedAnswer {

 List<String> get frames; Uri get link;
/// Create a copy of PresentedAnswer
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PresentedAnswerCopyWith<PresentedAnswer> get copyWith => _$PresentedAnswerCopyWithImpl<PresentedAnswer>(this as PresentedAnswer, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PresentedAnswer&&const DeepCollectionEquality().equals(other.frames, frames)&&(identical(other.link, link) || other.link == link));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(frames),link);

@override
String toString() {
  return 'PresentedAnswer(frames: $frames, link: $link)';
}


}

/// @nodoc
abstract mixin class $PresentedAnswerCopyWith<$Res>  {
  factory $PresentedAnswerCopyWith(PresentedAnswer value, $Res Function(PresentedAnswer) _then) = _$PresentedAnswerCopyWithImpl;
@useResult
$Res call({
 List<String> frames, Uri link
});




}
/// @nodoc
class _$PresentedAnswerCopyWithImpl<$Res>
    implements $PresentedAnswerCopyWith<$Res> {
  _$PresentedAnswerCopyWithImpl(this._self, this._then);

  final PresentedAnswer _self;
  final $Res Function(PresentedAnswer) _then;

/// Create a copy of PresentedAnswer
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? frames = null,Object? link = null,}) {
  return _then(_self.copyWith(
frames: null == frames ? _self.frames : frames // ignore: cast_nullable_to_non_nullable
as List<String>,link: null == link ? _self.link : link // ignore: cast_nullable_to_non_nullable
as Uri,
  ));
}

}


/// Adds pattern-matching-related methods to [PresentedAnswer].
extension PresentedAnswerPatterns on PresentedAnswer {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PresentedAnswer value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PresentedAnswer() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PresentedAnswer value)  $default,){
final _that = this;
switch (_that) {
case _PresentedAnswer():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PresentedAnswer value)?  $default,){
final _that = this;
switch (_that) {
case _PresentedAnswer() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<String> frames,  Uri link)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PresentedAnswer() when $default != null:
return $default(_that.frames,_that.link);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<String> frames,  Uri link)  $default,) {final _that = this;
switch (_that) {
case _PresentedAnswer():
return $default(_that.frames,_that.link);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<String> frames,  Uri link)?  $default,) {final _that = this;
switch (_that) {
case _PresentedAnswer() when $default != null:
return $default(_that.frames,_that.link);case _:
  return null;

}
}

}

/// @nodoc


class _PresentedAnswer implements PresentedAnswer {
  const _PresentedAnswer({required final  List<String> frames, required this.link}): _frames = frames;
  

 final  List<String> _frames;
@override List<String> get frames {
  if (_frames is EqualUnmodifiableListView) return _frames;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_frames);
}

@override final  Uri link;

/// Create a copy of PresentedAnswer
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PresentedAnswerCopyWith<_PresentedAnswer> get copyWith => __$PresentedAnswerCopyWithImpl<_PresentedAnswer>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PresentedAnswer&&const DeepCollectionEquality().equals(other._frames, _frames)&&(identical(other.link, link) || other.link == link));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_frames),link);

@override
String toString() {
  return 'PresentedAnswer(frames: $frames, link: $link)';
}


}

/// @nodoc
abstract mixin class _$PresentedAnswerCopyWith<$Res> implements $PresentedAnswerCopyWith<$Res> {
  factory _$PresentedAnswerCopyWith(_PresentedAnswer value, $Res Function(_PresentedAnswer) _then) = __$PresentedAnswerCopyWithImpl;
@override @useResult
$Res call({
 List<String> frames, Uri link
});




}
/// @nodoc
class __$PresentedAnswerCopyWithImpl<$Res>
    implements _$PresentedAnswerCopyWith<$Res> {
  __$PresentedAnswerCopyWithImpl(this._self, this._then);

  final _PresentedAnswer _self;
  final $Res Function(_PresentedAnswer) _then;

/// Create a copy of PresentedAnswer
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? frames = null,Object? link = null,}) {
  return _then(_PresentedAnswer(
frames: null == frames ? _self._frames : frames // ignore: cast_nullable_to_non_nullable
as List<String>,link: null == link ? _self.link : link // ignore: cast_nullable_to_non_nullable
as Uri,
  ));
}


}

// dart format on
