// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'auth_user.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AuthUser {

 String get uid; String get email; String? get displayName; String? get photoUrl; bool get emailVerified;/// Set only on a kid device, from its token's claim (accounts ADR-0003).
/// A kid device has no email, no account document and no household list;
/// the session routes it to the kid's home instead.
 KidIdentity? get kid;
/// Create a copy of AuthUser
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthUserCopyWith<AuthUser> get copyWith => _$AuthUserCopyWithImpl<AuthUser>(this as AuthUser, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AuthUser;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthUser&&(identical(other.uid, _this.uid) || other.uid == _this.uid)&&(identical(other.email, _this.email) || other.email == _this.email)&&(identical(other.displayName, _this.displayName) || other.displayName == _this.displayName)&&(identical(other.photoUrl, _this.photoUrl) || other.photoUrl == _this.photoUrl)&&(identical(other.emailVerified, _this.emailVerified) || other.emailVerified == _this.emailVerified)&&(identical(other.kid, _this.kid) || other.kid == _this.kid));
}


@override
int get hashCode {
  final _this = this as AuthUser;
  return Object.hash(runtimeType,_this.uid,_this.email,_this.displayName,_this.photoUrl,_this.emailVerified,_this.kid);
}

@override
String toString() {
  final _this = this as AuthUser;
  return 'AuthUser(uid: ${_this.uid}, email: ${_this.email}, displayName: ${_this.displayName}, photoUrl: ${_this.photoUrl}, emailVerified: ${_this.emailVerified}, kid: ${_this.kid})';
}


}

/// @nodoc
abstract mixin class $AuthUserCopyWith<$Res>  {
  factory $AuthUserCopyWith(AuthUser value, $Res Function(AuthUser) _then) = _$AuthUserCopyWithImpl;
@useResult
$Res call({
 String uid, String email, String? displayName, String? photoUrl, bool emailVerified, KidIdentity? kid
});


$KidIdentityCopyWith<$Res>? get kid;

}
/// @nodoc
class _$AuthUserCopyWithImpl<$Res>
    implements $AuthUserCopyWith<$Res> {
  _$AuthUserCopyWithImpl(this._self, this._then);

  final AuthUser _self;
  final $Res Function(AuthUser) _then;

/// Create a copy of AuthUser
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? uid = null,Object? email = null,Object? displayName = freezed,Object? photoUrl = freezed,Object? emailVerified = null,Object? kid = freezed,}) {
  return _then(AuthUser(
uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,photoUrl: freezed == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String?,emailVerified: null == emailVerified ? _self.emailVerified : emailVerified // ignore: cast_nullable_to_non_nullable
as bool,kid: freezed == kid ? _self.kid : kid // ignore: cast_nullable_to_non_nullable
as KidIdentity?,
  ));
}
/// Create a copy of AuthUser
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$KidIdentityCopyWith<$Res>? get kid {
    if (_self.kid == null) {
    return null;
  }

  return $KidIdentityCopyWith<$Res>(_self.kid!, (value) {
    return _then(_self.copyWith(kid: value));
  });
}
}


/// Adds pattern-matching-related methods to [AuthUser].
extension AuthUserPatterns on AuthUser {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AuthUser value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AuthUser() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AuthUser value)  $default,){
final _that = this;
switch (_that) {
case _AuthUser():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AuthUser value)?  $default,){
final _that = this;
switch (_that) {
case _AuthUser() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String uid,  String email,  String? displayName,  String? photoUrl,  bool emailVerified,  KidIdentity? kid)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AuthUser() when $default != null:
return $default(_that.uid,_that.email,_that.displayName,_that.photoUrl,_that.emailVerified,_that.kid);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String uid,  String email,  String? displayName,  String? photoUrl,  bool emailVerified,  KidIdentity? kid)  $default,) {final _that = this;
switch (_that) {
case _AuthUser():
return $default(_that.uid,_that.email,_that.displayName,_that.photoUrl,_that.emailVerified,_that.kid);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String uid,  String email,  String? displayName,  String? photoUrl,  bool emailVerified,  KidIdentity? kid)?  $default,) {final _that = this;
switch (_that) {
case _AuthUser() when $default != null:
return $default(_that.uid,_that.email,_that.displayName,_that.photoUrl,_that.emailVerified,_that.kid);case _:
  return null;

}
}

}

/// @nodoc


class _AuthUser extends AuthUser {
  const _AuthUser({required this.uid, required this.email, this.displayName, this.photoUrl, this.emailVerified = false, this.kid}): super._();
  

@override final  String uid;
@override final  String email;
@override final  String? displayName;
@override final  String? photoUrl;
@override@JsonKey() final  bool emailVerified;
/// Set only on a kid device, from its token's claim (accounts ADR-0003).
/// A kid device has no email, no account document and no household list;
/// the session routes it to the kid's home instead.
@override final  KidIdentity? kid;

/// Create a copy of AuthUser
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuthUserCopyWith<_AuthUser> get copyWith => __$AuthUserCopyWithImpl<_AuthUser>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuthUser&&(identical(other.uid, uid) || other.uid == uid)&&(identical(other.email, email) || other.email == email)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl)&&(identical(other.emailVerified, emailVerified) || other.emailVerified == emailVerified)&&(identical(other.kid, kid) || other.kid == kid));
}


@override
int get hashCode {
    return Object.hash(runtimeType,uid,email,displayName,photoUrl,emailVerified,kid);
}

@override
String toString() {
    return 'AuthUser(uid: $uid, email: $email, displayName: $displayName, photoUrl: $photoUrl, emailVerified: $emailVerified, kid: $kid)';
}


}

/// @nodoc
abstract mixin class _$AuthUserCopyWith<$Res> implements $AuthUserCopyWith<$Res> {
  factory _$AuthUserCopyWith(_AuthUser value, $Res Function(_AuthUser) _then) = __$AuthUserCopyWithImpl;
@override @useResult
$Res call({
 String uid, String email, String? displayName, String? photoUrl, bool emailVerified, KidIdentity? kid
});


@override $KidIdentityCopyWith<$Res>? get kid;

}
/// @nodoc
class __$AuthUserCopyWithImpl<$Res>
    implements _$AuthUserCopyWith<$Res> {
  __$AuthUserCopyWithImpl(this._self, this._then);

  final _AuthUser _self;
  final $Res Function(_AuthUser) _then;

/// Create a copy of AuthUser
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? uid = null,Object? email = null,Object? displayName = freezed,Object? photoUrl = freezed,Object? emailVerified = null,Object? kid = freezed,}) {
  return _then(_AuthUser(
uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,photoUrl: freezed == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String?,emailVerified: null == emailVerified ? _self.emailVerified : emailVerified // ignore: cast_nullable_to_non_nullable
as bool,kid: freezed == kid ? _self.kid : kid // ignore: cast_nullable_to_non_nullable
as KidIdentity?,
  ));
}

/// Create a copy of AuthUser
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$KidIdentityCopyWith<$Res>? get kid {
    if (_self.kid == null) {
    return null;
  }

  return $KidIdentityCopyWith<$Res>(_self.kid!, (value) {
    return _then(_self.copyWith(kid: value));
  });
}
}

// dart format on
