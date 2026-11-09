// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'authenticated_account.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AuthenticatedAccount {

 int get id; String get email; String get role; String get principalId;
/// Create a copy of AuthenticatedAccount
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthenticatedAccountCopyWith<AuthenticatedAccount> get copyWith => _$AuthenticatedAccountCopyWithImpl<AuthenticatedAccount>(this as AuthenticatedAccount, _$identity);

  /// Serializes this AuthenticatedAccount to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthenticatedAccount&&(identical(other.id, id) || other.id == id)&&(identical(other.email, email) || other.email == email)&&(identical(other.role, role) || other.role == role)&&(identical(other.principalId, principalId) || other.principalId == principalId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,email,role,principalId);

@override
String toString() {
  return 'AuthenticatedAccount(id: $id, email: $email, role: $role, principalId: $principalId)';
}


}

/// @nodoc
abstract mixin class $AuthenticatedAccountCopyWith<$Res>  {
  factory $AuthenticatedAccountCopyWith(AuthenticatedAccount value, $Res Function(AuthenticatedAccount) _then) = _$AuthenticatedAccountCopyWithImpl;
@useResult
$Res call({
 int id, String email, String role, String principalId
});




}
/// @nodoc
class _$AuthenticatedAccountCopyWithImpl<$Res>
    implements $AuthenticatedAccountCopyWith<$Res> {
  _$AuthenticatedAccountCopyWithImpl(this._self, this._then);

  final AuthenticatedAccount _self;
  final $Res Function(AuthenticatedAccount) _then;

/// Create a copy of AuthenticatedAccount
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? email = null,Object? role = null,Object? principalId = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,principalId: null == principalId ? _self.principalId : principalId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [AuthenticatedAccount].
extension AuthenticatedAccountPatterns on AuthenticatedAccount {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AuthenticatedAccount value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AuthenticatedAccount() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AuthenticatedAccount value)  $default,){
final _that = this;
switch (_that) {
case _AuthenticatedAccount():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AuthenticatedAccount value)?  $default,){
final _that = this;
switch (_that) {
case _AuthenticatedAccount() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String email,  String role,  String principalId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AuthenticatedAccount() when $default != null:
return $default(_that.id,_that.email,_that.role,_that.principalId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String email,  String role,  String principalId)  $default,) {final _that = this;
switch (_that) {
case _AuthenticatedAccount():
return $default(_that.id,_that.email,_that.role,_that.principalId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String email,  String role,  String principalId)?  $default,) {final _that = this;
switch (_that) {
case _AuthenticatedAccount() when $default != null:
return $default(_that.id,_that.email,_that.role,_that.principalId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AuthenticatedAccount implements AuthenticatedAccount {
  const _AuthenticatedAccount({required this.id, required this.email, required this.role, required this.principalId});
  factory _AuthenticatedAccount.fromJson(Map<String, dynamic> json) => _$AuthenticatedAccountFromJson(json);

@override final  int id;
@override final  String email;
@override final  String role;
@override final  String principalId;

/// Create a copy of AuthenticatedAccount
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuthenticatedAccountCopyWith<_AuthenticatedAccount> get copyWith => __$AuthenticatedAccountCopyWithImpl<_AuthenticatedAccount>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AuthenticatedAccountToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuthenticatedAccount&&(identical(other.id, id) || other.id == id)&&(identical(other.email, email) || other.email == email)&&(identical(other.role, role) || other.role == role)&&(identical(other.principalId, principalId) || other.principalId == principalId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,email,role,principalId);

@override
String toString() {
  return 'AuthenticatedAccount(id: $id, email: $email, role: $role, principalId: $principalId)';
}


}

/// @nodoc
abstract mixin class _$AuthenticatedAccountCopyWith<$Res> implements $AuthenticatedAccountCopyWith<$Res> {
  factory _$AuthenticatedAccountCopyWith(_AuthenticatedAccount value, $Res Function(_AuthenticatedAccount) _then) = __$AuthenticatedAccountCopyWithImpl;
@override @useResult
$Res call({
 int id, String email, String role, String principalId
});




}
/// @nodoc
class __$AuthenticatedAccountCopyWithImpl<$Res>
    implements _$AuthenticatedAccountCopyWith<$Res> {
  __$AuthenticatedAccountCopyWithImpl(this._self, this._then);

  final _AuthenticatedAccount _self;
  final $Res Function(_AuthenticatedAccount) _then;

/// Create a copy of AuthenticatedAccount
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? email = null,Object? role = null,Object? principalId = null,}) {
  return _then(_AuthenticatedAccount(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,principalId: null == principalId ? _self.principalId : principalId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
