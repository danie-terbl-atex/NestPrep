// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'push_token.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PushToken {

@JsonKey(includeToJson: false) String get id; String get token; PushPlatform get platform;@ServerTimestampConverter() DateTime? get updatedAt;
/// Create a copy of PushToken
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PushTokenCopyWith<PushToken> get copyWith => _$PushTokenCopyWithImpl<PushToken>(this as PushToken, _$identity);

  /// Serializes this PushToken to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PushToken;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PushToken&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.token, _this.token) || other.token == _this.token)&&(identical(other.platform, _this.platform) || other.platform == _this.platform)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PushToken;
  return Object.hash(runtimeType,_this.id,_this.token,_this.platform,_this.updatedAt);
}

@override
String toString() {
  final _this = this as PushToken;
  return 'PushToken(id: ${_this.id}, token: ${_this.token}, platform: ${_this.platform}, updatedAt: ${_this.updatedAt})';
}


}

/// @nodoc
abstract mixin class $PushTokenCopyWith<$Res>  {
  factory $PushTokenCopyWith(PushToken value, $Res Function(PushToken) _then) = _$PushTokenCopyWithImpl;
@useResult
$Res call({
@JsonKey(includeToJson: false) String id, String token, PushPlatform platform,@ServerTimestampConverter() DateTime? updatedAt
});




}
/// @nodoc
class _$PushTokenCopyWithImpl<$Res>
    implements $PushTokenCopyWith<$Res> {
  _$PushTokenCopyWithImpl(this._self, this._then);

  final PushToken _self;
  final $Res Function(PushToken) _then;

/// Create a copy of PushToken
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? token = null,Object? platform = null,Object? updatedAt = freezed,}) {
  return _then(PushToken(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,platform: null == platform ? _self.platform : platform // ignore: cast_nullable_to_non_nullable
as PushPlatform,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [PushToken].
extension PushTokenPatterns on PushToken {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PushToken value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PushToken() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PushToken value)  $default,){
final _that = this;
switch (_that) {
case _PushToken():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PushToken value)?  $default,){
final _that = this;
switch (_that) {
case _PushToken() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  String token,  PushPlatform platform, @ServerTimestampConverter()  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PushToken() when $default != null:
return $default(_that.id,_that.token,_that.platform,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  String token,  PushPlatform platform, @ServerTimestampConverter()  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _PushToken():
return $default(_that.id,_that.token,_that.platform,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(includeToJson: false)  String id,  String token,  PushPlatform platform, @ServerTimestampConverter()  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _PushToken() when $default != null:
return $default(_that.id,_that.token,_that.platform,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PushToken implements PushToken {
  const _PushToken({@JsonKey(includeToJson: false) required this.id, required this.token, required this.platform, @ServerTimestampConverter() this.updatedAt});
  factory _PushToken.fromJson(Map<String, dynamic> json) => _$PushTokenFromJson(json);

@override@JsonKey(includeToJson: false) final  String id;
@override final  String token;
@override final  PushPlatform platform;
@override@ServerTimestampConverter() final  DateTime? updatedAt;

/// Create a copy of PushToken
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PushTokenCopyWith<_PushToken> get copyWith => __$PushTokenCopyWithImpl<_PushToken>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PushTokenToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PushToken&&(identical(other.id, id) || other.id == id)&&(identical(other.token, token) || other.token == token)&&(identical(other.platform, platform) || other.platform == platform)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,token,platform,updatedAt);
}

@override
String toString() {
    return 'PushToken(id: $id, token: $token, platform: $platform, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$PushTokenCopyWith<$Res> implements $PushTokenCopyWith<$Res> {
  factory _$PushTokenCopyWith(_PushToken value, $Res Function(_PushToken) _then) = __$PushTokenCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(includeToJson: false) String id, String token, PushPlatform platform,@ServerTimestampConverter() DateTime? updatedAt
});




}
/// @nodoc
class __$PushTokenCopyWithImpl<$Res>
    implements _$PushTokenCopyWith<$Res> {
  __$PushTokenCopyWithImpl(this._self, this._then);

  final _PushToken _self;
  final $Res Function(_PushToken) _then;

/// Create a copy of PushToken
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? token = null,Object? platform = null,Object? updatedAt = freezed,}) {
  return _then(_PushToken(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,platform: null == platform ? _self.platform : platform // ignore: cast_nullable_to_non_nullable
as PushPlatform,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
