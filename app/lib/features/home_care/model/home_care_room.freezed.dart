// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'home_care_room.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$HomeCareRoom {

@JsonKey(includeToJson: false) String get id; String get name;@JsonKey(unknownEnumValue: RoomKind.other) RoomKind get kind;/// The member profile that added it, not the account.
 String get createdBy;@ServerTimestampConverter() DateTime? get createdAt;
/// Create a copy of HomeCareRoom
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HomeCareRoomCopyWith<HomeCareRoom> get copyWith => _$HomeCareRoomCopyWithImpl<HomeCareRoom>(this as HomeCareRoom, _$identity);

  /// Serializes this HomeCareRoom to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as HomeCareRoom;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HomeCareRoom&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.createdBy, _this.createdBy) || other.createdBy == _this.createdBy)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as HomeCareRoom;
  return Object.hash(runtimeType,_this.id,_this.name,_this.kind,_this.createdBy,_this.createdAt);
}

@override
String toString() {
  final _this = this as HomeCareRoom;
  return 'HomeCareRoom(id: ${_this.id}, name: ${_this.name}, kind: ${_this.kind}, createdBy: ${_this.createdBy}, createdAt: ${_this.createdAt})';
}


}

/// @nodoc
abstract mixin class $HomeCareRoomCopyWith<$Res>  {
  factory $HomeCareRoomCopyWith(HomeCareRoom value, $Res Function(HomeCareRoom) _then) = _$HomeCareRoomCopyWithImpl;
@useResult
$Res call({
@JsonKey(includeToJson: false) String id, String name,@JsonKey(unknownEnumValue: RoomKind.other) RoomKind kind, String createdBy,@ServerTimestampConverter() DateTime? createdAt
});




}
/// @nodoc
class _$HomeCareRoomCopyWithImpl<$Res>
    implements $HomeCareRoomCopyWith<$Res> {
  _$HomeCareRoomCopyWithImpl(this._self, this._then);

  final HomeCareRoom _self;
  final $Res Function(HomeCareRoom) _then;

/// Create a copy of HomeCareRoom
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? kind = null,Object? createdBy = null,Object? createdAt = freezed,}) {
  return _then(HomeCareRoom(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as RoomKind,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [HomeCareRoom].
extension HomeCareRoomPatterns on HomeCareRoom {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HomeCareRoom value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HomeCareRoom() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HomeCareRoom value)  $default,){
final _that = this;
switch (_that) {
case _HomeCareRoom():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HomeCareRoom value)?  $default,){
final _that = this;
switch (_that) {
case _HomeCareRoom() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  String name, @JsonKey(unknownEnumValue: RoomKind.other)  RoomKind kind,  String createdBy, @ServerTimestampConverter()  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HomeCareRoom() when $default != null:
return $default(_that.id,_that.name,_that.kind,_that.createdBy,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  String name, @JsonKey(unknownEnumValue: RoomKind.other)  RoomKind kind,  String createdBy, @ServerTimestampConverter()  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _HomeCareRoom():
return $default(_that.id,_that.name,_that.kind,_that.createdBy,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(includeToJson: false)  String id,  String name, @JsonKey(unknownEnumValue: RoomKind.other)  RoomKind kind,  String createdBy, @ServerTimestampConverter()  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _HomeCareRoom() when $default != null:
return $default(_that.id,_that.name,_that.kind,_that.createdBy,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HomeCareRoom implements HomeCareRoom {
  const _HomeCareRoom({@JsonKey(includeToJson: false) required this.id, required this.name, @JsonKey(unknownEnumValue: RoomKind.other) required this.kind, required this.createdBy, @ServerTimestampConverter() this.createdAt});
  factory _HomeCareRoom.fromJson(Map<String, dynamic> json) => _$HomeCareRoomFromJson(json);

@override@JsonKey(includeToJson: false) final  String id;
@override final  String name;
@override@JsonKey(unknownEnumValue: RoomKind.other) final  RoomKind kind;
/// The member profile that added it, not the account.
@override final  String createdBy;
@override@ServerTimestampConverter() final  DateTime? createdAt;

/// Create a copy of HomeCareRoom
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HomeCareRoomCopyWith<_HomeCareRoom> get copyWith => __$HomeCareRoomCopyWithImpl<_HomeCareRoom>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HomeCareRoomToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _HomeCareRoom&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,kind,createdBy,createdAt);
}

@override
String toString() {
    return 'HomeCareRoom(id: $id, name: $name, kind: $kind, createdBy: $createdBy, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$HomeCareRoomCopyWith<$Res> implements $HomeCareRoomCopyWith<$Res> {
  factory _$HomeCareRoomCopyWith(_HomeCareRoom value, $Res Function(_HomeCareRoom) _then) = __$HomeCareRoomCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(includeToJson: false) String id, String name,@JsonKey(unknownEnumValue: RoomKind.other) RoomKind kind, String createdBy,@ServerTimestampConverter() DateTime? createdAt
});




}
/// @nodoc
class __$HomeCareRoomCopyWithImpl<$Res>
    implements _$HomeCareRoomCopyWith<$Res> {
  __$HomeCareRoomCopyWithImpl(this._self, this._then);

  final _HomeCareRoom _self;
  final $Res Function(_HomeCareRoom) _then;

/// Create a copy of HomeCareRoom
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? kind = null,Object? createdBy = null,Object? createdAt = freezed,}) {
  return _then(_HomeCareRoom(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as RoomKind,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
