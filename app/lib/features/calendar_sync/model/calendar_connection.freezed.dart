// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'calendar_connection.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CalendarConnection {

@JsonKey(includeToJson: false) String get id;@JsonKey(unknownEnumValue: CalendarProvider.ics) CalendarProvider get provider;/// The member whose calendar it is; imported events are drawn in their
/// colour.
 String get memberId; String get ownerUid;/// The account's address, or a calendar link's host.
 String get accountLabel;/// A status this build has never heard of reads as unreachable: something
/// is wrong, and the next sync will say what (`BE-10`).
@JsonKey(unknownEnumValue: ConnectionStatus.unreachable) ConnectionStatus get status; int get eventCount;@NullableTimestampConverter() DateTime? get lastSyncedAt;
/// Create a copy of CalendarConnection
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CalendarConnectionCopyWith<CalendarConnection> get copyWith => _$CalendarConnectionCopyWithImpl<CalendarConnection>(this as CalendarConnection, _$identity);

  /// Serializes this CalendarConnection to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as CalendarConnection;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CalendarConnection&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.provider, _this.provider) || other.provider == _this.provider)&&(identical(other.memberId, _this.memberId) || other.memberId == _this.memberId)&&(identical(other.ownerUid, _this.ownerUid) || other.ownerUid == _this.ownerUid)&&(identical(other.accountLabel, _this.accountLabel) || other.accountLabel == _this.accountLabel)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.eventCount, _this.eventCount) || other.eventCount == _this.eventCount)&&(identical(other.lastSyncedAt, _this.lastSyncedAt) || other.lastSyncedAt == _this.lastSyncedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CalendarConnection;
  return Object.hash(runtimeType,_this.id,_this.provider,_this.memberId,_this.ownerUid,_this.accountLabel,_this.status,_this.eventCount,_this.lastSyncedAt);
}

@override
String toString() {
  final _this = this as CalendarConnection;
  return 'CalendarConnection(id: ${_this.id}, provider: ${_this.provider}, memberId: ${_this.memberId}, ownerUid: ${_this.ownerUid}, accountLabel: ${_this.accountLabel}, status: ${_this.status}, eventCount: ${_this.eventCount}, lastSyncedAt: ${_this.lastSyncedAt})';
}


}

/// @nodoc
abstract mixin class $CalendarConnectionCopyWith<$Res>  {
  factory $CalendarConnectionCopyWith(CalendarConnection value, $Res Function(CalendarConnection) _then) = _$CalendarConnectionCopyWithImpl;
@useResult
$Res call({
@JsonKey(includeToJson: false) String id,@JsonKey(unknownEnumValue: CalendarProvider.ics) CalendarProvider provider, String memberId, String ownerUid, String accountLabel,@JsonKey(unknownEnumValue: ConnectionStatus.unreachable) ConnectionStatus status, int eventCount,@NullableTimestampConverter() DateTime? lastSyncedAt
});




}
/// @nodoc
class _$CalendarConnectionCopyWithImpl<$Res>
    implements $CalendarConnectionCopyWith<$Res> {
  _$CalendarConnectionCopyWithImpl(this._self, this._then);

  final CalendarConnection _self;
  final $Res Function(CalendarConnection) _then;

/// Create a copy of CalendarConnection
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? provider = null,Object? memberId = null,Object? ownerUid = null,Object? accountLabel = null,Object? status = null,Object? eventCount = null,Object? lastSyncedAt = freezed,}) {
  return _then(CalendarConnection(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,provider: null == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as CalendarProvider,memberId: null == memberId ? _self.memberId : memberId // ignore: cast_nullable_to_non_nullable
as String,ownerUid: null == ownerUid ? _self.ownerUid : ownerUid // ignore: cast_nullable_to_non_nullable
as String,accountLabel: null == accountLabel ? _self.accountLabel : accountLabel // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ConnectionStatus,eventCount: null == eventCount ? _self.eventCount : eventCount // ignore: cast_nullable_to_non_nullable
as int,lastSyncedAt: freezed == lastSyncedAt ? _self.lastSyncedAt : lastSyncedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [CalendarConnection].
extension CalendarConnectionPatterns on CalendarConnection {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CalendarConnection value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CalendarConnection() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CalendarConnection value)  $default,){
final _that = this;
switch (_that) {
case _CalendarConnection():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CalendarConnection value)?  $default,){
final _that = this;
switch (_that) {
case _CalendarConnection() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id, @JsonKey(unknownEnumValue: CalendarProvider.ics)  CalendarProvider provider,  String memberId,  String ownerUid,  String accountLabel, @JsonKey(unknownEnumValue: ConnectionStatus.unreachable)  ConnectionStatus status,  int eventCount, @NullableTimestampConverter()  DateTime? lastSyncedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CalendarConnection() when $default != null:
return $default(_that.id,_that.provider,_that.memberId,_that.ownerUid,_that.accountLabel,_that.status,_that.eventCount,_that.lastSyncedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id, @JsonKey(unknownEnumValue: CalendarProvider.ics)  CalendarProvider provider,  String memberId,  String ownerUid,  String accountLabel, @JsonKey(unknownEnumValue: ConnectionStatus.unreachable)  ConnectionStatus status,  int eventCount, @NullableTimestampConverter()  DateTime? lastSyncedAt)  $default,) {final _that = this;
switch (_that) {
case _CalendarConnection():
return $default(_that.id,_that.provider,_that.memberId,_that.ownerUid,_that.accountLabel,_that.status,_that.eventCount,_that.lastSyncedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(includeToJson: false)  String id, @JsonKey(unknownEnumValue: CalendarProvider.ics)  CalendarProvider provider,  String memberId,  String ownerUid,  String accountLabel, @JsonKey(unknownEnumValue: ConnectionStatus.unreachable)  ConnectionStatus status,  int eventCount, @NullableTimestampConverter()  DateTime? lastSyncedAt)?  $default,) {final _that = this;
switch (_that) {
case _CalendarConnection() when $default != null:
return $default(_that.id,_that.provider,_that.memberId,_that.ownerUid,_that.accountLabel,_that.status,_that.eventCount,_that.lastSyncedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CalendarConnection extends CalendarConnection {
  const _CalendarConnection({@JsonKey(includeToJson: false) required this.id, @JsonKey(unknownEnumValue: CalendarProvider.ics) required this.provider, required this.memberId, required this.ownerUid, this.accountLabel = '', @JsonKey(unknownEnumValue: ConnectionStatus.unreachable) this.status = ConnectionStatus.connected, this.eventCount = 0, @NullableTimestampConverter() this.lastSyncedAt}): super._();
  factory _CalendarConnection.fromJson(Map<String, dynamic> json) => _$CalendarConnectionFromJson(json);

@override@JsonKey(includeToJson: false) final  String id;
@override@JsonKey(unknownEnumValue: CalendarProvider.ics) final  CalendarProvider provider;
/// The member whose calendar it is; imported events are drawn in their
/// colour.
@override final  String memberId;
@override final  String ownerUid;
/// The account's address, or a calendar link's host.
@override@JsonKey() final  String accountLabel;
/// A status this build has never heard of reads as unreachable: something
/// is wrong, and the next sync will say what (`BE-10`).
@override@JsonKey(unknownEnumValue: ConnectionStatus.unreachable) final  ConnectionStatus status;
@override@JsonKey() final  int eventCount;
@override@NullableTimestampConverter() final  DateTime? lastSyncedAt;

/// Create a copy of CalendarConnection
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CalendarConnectionCopyWith<_CalendarConnection> get copyWith => __$CalendarConnectionCopyWithImpl<_CalendarConnection>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CalendarConnectionToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CalendarConnection&&(identical(other.id, id) || other.id == id)&&(identical(other.provider, provider) || other.provider == provider)&&(identical(other.memberId, memberId) || other.memberId == memberId)&&(identical(other.ownerUid, ownerUid) || other.ownerUid == ownerUid)&&(identical(other.accountLabel, accountLabel) || other.accountLabel == accountLabel)&&(identical(other.status, status) || other.status == status)&&(identical(other.eventCount, eventCount) || other.eventCount == eventCount)&&(identical(other.lastSyncedAt, lastSyncedAt) || other.lastSyncedAt == lastSyncedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,provider,memberId,ownerUid,accountLabel,status,eventCount,lastSyncedAt);
}

@override
String toString() {
    return 'CalendarConnection(id: $id, provider: $provider, memberId: $memberId, ownerUid: $ownerUid, accountLabel: $accountLabel, status: $status, eventCount: $eventCount, lastSyncedAt: $lastSyncedAt)';
}


}

/// @nodoc
abstract mixin class _$CalendarConnectionCopyWith<$Res> implements $CalendarConnectionCopyWith<$Res> {
  factory _$CalendarConnectionCopyWith(_CalendarConnection value, $Res Function(_CalendarConnection) _then) = __$CalendarConnectionCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(includeToJson: false) String id,@JsonKey(unknownEnumValue: CalendarProvider.ics) CalendarProvider provider, String memberId, String ownerUid, String accountLabel,@JsonKey(unknownEnumValue: ConnectionStatus.unreachable) ConnectionStatus status, int eventCount,@NullableTimestampConverter() DateTime? lastSyncedAt
});




}
/// @nodoc
class __$CalendarConnectionCopyWithImpl<$Res>
    implements _$CalendarConnectionCopyWith<$Res> {
  __$CalendarConnectionCopyWithImpl(this._self, this._then);

  final _CalendarConnection _self;
  final $Res Function(_CalendarConnection) _then;

/// Create a copy of CalendarConnection
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? provider = null,Object? memberId = null,Object? ownerUid = null,Object? accountLabel = null,Object? status = null,Object? eventCount = null,Object? lastSyncedAt = freezed,}) {
  return _then(_CalendarConnection(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,provider: null == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as CalendarProvider,memberId: null == memberId ? _self.memberId : memberId // ignore: cast_nullable_to_non_nullable
as String,ownerUid: null == ownerUid ? _self.ownerUid : ownerUid // ignore: cast_nullable_to_non_nullable
as String,accountLabel: null == accountLabel ? _self.accountLabel : accountLabel // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ConnectionStatus,eventCount: null == eventCount ? _self.eventCount : eventCount // ignore: cast_nullable_to_non_nullable
as int,lastSyncedAt: freezed == lastSyncedAt ? _self.lastSyncedAt : lastSyncedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
