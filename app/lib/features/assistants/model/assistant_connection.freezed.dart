// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'assistant_connection.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AssistantConnection {

@JsonKey(includeToJson: false) String get id;/// The account that connected it, and the profile it acts as.
 String get uid; String get memberId;/// What the assistant calls itself, from its client registration.
 String get clientName; String get host;@JsonKey(unknownEnumValue: AssistantVia.assistant) AssistantVia get via; List<String> get scopes;@NullableTimestampConverter() DateTime? get createdAt;@NullableTimestampConverter() DateTime? get lastUsedAt;
/// Create a copy of AssistantConnection
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AssistantConnectionCopyWith<AssistantConnection> get copyWith => _$AssistantConnectionCopyWithImpl<AssistantConnection>(this as AssistantConnection, _$identity);

  /// Serializes this AssistantConnection to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as AssistantConnection;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AssistantConnection&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.uid, _this.uid) || other.uid == _this.uid)&&(identical(other.memberId, _this.memberId) || other.memberId == _this.memberId)&&(identical(other.clientName, _this.clientName) || other.clientName == _this.clientName)&&(identical(other.host, _this.host) || other.host == _this.host)&&(identical(other.via, _this.via) || other.via == _this.via)&&const DeepCollectionEquality().equals(other.scopes, _this.scopes)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.lastUsedAt, _this.lastUsedAt) || other.lastUsedAt == _this.lastUsedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as AssistantConnection;
  return Object.hash(runtimeType,_this.id,_this.uid,_this.memberId,_this.clientName,_this.host,_this.via,const DeepCollectionEquality().hash(_this.scopes),_this.createdAt,_this.lastUsedAt);
}

@override
String toString() {
  final _this = this as AssistantConnection;
  return 'AssistantConnection(id: ${_this.id}, uid: ${_this.uid}, memberId: ${_this.memberId}, clientName: ${_this.clientName}, host: ${_this.host}, via: ${_this.via}, scopes: ${_this.scopes}, createdAt: ${_this.createdAt}, lastUsedAt: ${_this.lastUsedAt})';
}


}

/// @nodoc
abstract mixin class $AssistantConnectionCopyWith<$Res>  {
  factory $AssistantConnectionCopyWith(AssistantConnection value, $Res Function(AssistantConnection) _then) = _$AssistantConnectionCopyWithImpl;
@useResult
$Res call({
@JsonKey(includeToJson: false) String id, String uid, String memberId, String clientName, String host,@JsonKey(unknownEnumValue: AssistantVia.assistant) AssistantVia via, List<String> scopes,@NullableTimestampConverter() DateTime? createdAt,@NullableTimestampConverter() DateTime? lastUsedAt
});




}
/// @nodoc
class _$AssistantConnectionCopyWithImpl<$Res>
    implements $AssistantConnectionCopyWith<$Res> {
  _$AssistantConnectionCopyWithImpl(this._self, this._then);

  final AssistantConnection _self;
  final $Res Function(AssistantConnection) _then;

/// Create a copy of AssistantConnection
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? uid = null,Object? memberId = null,Object? clientName = null,Object? host = null,Object? via = null,Object? scopes = null,Object? createdAt = freezed,Object? lastUsedAt = freezed,}) {
  return _then(AssistantConnection(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as String,memberId: null == memberId ? _self.memberId : memberId // ignore: cast_nullable_to_non_nullable
as String,clientName: null == clientName ? _self.clientName : clientName // ignore: cast_nullable_to_non_nullable
as String,host: null == host ? _self.host : host // ignore: cast_nullable_to_non_nullable
as String,via: null == via ? _self.via : via // ignore: cast_nullable_to_non_nullable
as AssistantVia,scopes: null == scopes ? _self.scopes : scopes // ignore: cast_nullable_to_non_nullable
as List<String>,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastUsedAt: freezed == lastUsedAt ? _self.lastUsedAt : lastUsedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [AssistantConnection].
extension AssistantConnectionPatterns on AssistantConnection {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AssistantConnection value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AssistantConnection() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AssistantConnection value)  $default,){
final _that = this;
switch (_that) {
case _AssistantConnection():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AssistantConnection value)?  $default,){
final _that = this;
switch (_that) {
case _AssistantConnection() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  String uid,  String memberId,  String clientName,  String host, @JsonKey(unknownEnumValue: AssistantVia.assistant)  AssistantVia via,  List<String> scopes, @NullableTimestampConverter()  DateTime? createdAt, @NullableTimestampConverter()  DateTime? lastUsedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AssistantConnection() when $default != null:
return $default(_that.id,_that.uid,_that.memberId,_that.clientName,_that.host,_that.via,_that.scopes,_that.createdAt,_that.lastUsedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  String uid,  String memberId,  String clientName,  String host, @JsonKey(unknownEnumValue: AssistantVia.assistant)  AssistantVia via,  List<String> scopes, @NullableTimestampConverter()  DateTime? createdAt, @NullableTimestampConverter()  DateTime? lastUsedAt)  $default,) {final _that = this;
switch (_that) {
case _AssistantConnection():
return $default(_that.id,_that.uid,_that.memberId,_that.clientName,_that.host,_that.via,_that.scopes,_that.createdAt,_that.lastUsedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(includeToJson: false)  String id,  String uid,  String memberId,  String clientName,  String host, @JsonKey(unknownEnumValue: AssistantVia.assistant)  AssistantVia via,  List<String> scopes, @NullableTimestampConverter()  DateTime? createdAt, @NullableTimestampConverter()  DateTime? lastUsedAt)?  $default,) {final _that = this;
switch (_that) {
case _AssistantConnection() when $default != null:
return $default(_that.id,_that.uid,_that.memberId,_that.clientName,_that.host,_that.via,_that.scopes,_that.createdAt,_that.lastUsedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AssistantConnection extends AssistantConnection {
  const _AssistantConnection({@JsonKey(includeToJson: false) required this.id, required this.uid, required this.memberId, this.clientName = '', this.host = '', @JsonKey(unknownEnumValue: AssistantVia.assistant) this.via = AssistantVia.assistant,  List<String> scopes = const <String>[], @NullableTimestampConverter() this.createdAt, @NullableTimestampConverter() this.lastUsedAt}): _scopes = scopes,super._();
  factory _AssistantConnection.fromJson(Map<String, dynamic> json) => _$AssistantConnectionFromJson(json);

@override@JsonKey(includeToJson: false) final  String id;
/// The account that connected it, and the profile it acts as.
@override final  String uid;
@override final  String memberId;
/// What the assistant calls itself, from its client registration.
@override@JsonKey() final  String clientName;
@override@JsonKey() final  String host;
@override@JsonKey(unknownEnumValue: AssistantVia.assistant) final  AssistantVia via;
 final  List<String> _scopes;
@override@JsonKey() List<String> get scopes {
  if (_scopes is EqualUnmodifiableListView) return _scopes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_scopes);
}

@override@NullableTimestampConverter() final  DateTime? createdAt;
@override@NullableTimestampConverter() final  DateTime? lastUsedAt;

/// Create a copy of AssistantConnection
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AssistantConnectionCopyWith<_AssistantConnection> get copyWith => __$AssistantConnectionCopyWithImpl<_AssistantConnection>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AssistantConnectionToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AssistantConnection&&(identical(other.id, id) || other.id == id)&&(identical(other.uid, uid) || other.uid == uid)&&(identical(other.memberId, memberId) || other.memberId == memberId)&&(identical(other.clientName, clientName) || other.clientName == clientName)&&(identical(other.host, host) || other.host == host)&&(identical(other.via, via) || other.via == via)&&const DeepCollectionEquality().equals(other.scopes, _scopes)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.lastUsedAt, lastUsedAt) || other.lastUsedAt == lastUsedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,uid,memberId,clientName,host,via,const DeepCollectionEquality().hash(_scopes),createdAt,lastUsedAt);
}

@override
String toString() {
    return 'AssistantConnection(id: $id, uid: $uid, memberId: $memberId, clientName: $clientName, host: $host, via: $via, scopes: $scopes, createdAt: $createdAt, lastUsedAt: $lastUsedAt)';
}


}

/// @nodoc
abstract mixin class _$AssistantConnectionCopyWith<$Res> implements $AssistantConnectionCopyWith<$Res> {
  factory _$AssistantConnectionCopyWith(_AssistantConnection value, $Res Function(_AssistantConnection) _then) = __$AssistantConnectionCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(includeToJson: false) String id, String uid, String memberId, String clientName, String host,@JsonKey(unknownEnumValue: AssistantVia.assistant) AssistantVia via, List<String> scopes,@NullableTimestampConverter() DateTime? createdAt,@NullableTimestampConverter() DateTime? lastUsedAt
});




}
/// @nodoc
class __$AssistantConnectionCopyWithImpl<$Res>
    implements _$AssistantConnectionCopyWith<$Res> {
  __$AssistantConnectionCopyWithImpl(this._self, this._then);

  final _AssistantConnection _self;
  final $Res Function(_AssistantConnection) _then;

/// Create a copy of AssistantConnection
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? uid = null,Object? memberId = null,Object? clientName = null,Object? host = null,Object? via = null,Object? scopes = null,Object? createdAt = freezed,Object? lastUsedAt = freezed,}) {
  return _then(_AssistantConnection(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as String,memberId: null == memberId ? _self.memberId : memberId // ignore: cast_nullable_to_non_nullable
as String,clientName: null == clientName ? _self.clientName : clientName // ignore: cast_nullable_to_non_nullable
as String,host: null == host ? _self.host : host // ignore: cast_nullable_to_non_nullable
as String,via: null == via ? _self.via : via // ignore: cast_nullable_to_non_nullable
as AssistantVia,scopes: null == scopes ? _self._scopes : scopes // ignore: cast_nullable_to_non_nullable
as List<String>,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastUsedAt: freezed == lastUsedAt ? _self.lastUsedAt : lastUsedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
