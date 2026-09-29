// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'handover_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$HandoverEntry {

@JsonKey(includeToJson: false) String get id;@JsonKey(unknownEnumValue: HandoverKind.note) HandoverKind get kind; String? get note;@JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) HandoverMood? get mood; List<String> get childIds; String? get photoId;@InstantConverter() DateTime get at; String get byMemberId;@ServerTimestampConverter() DateTime? get createdAt;
/// Create a copy of HandoverEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HandoverEntryCopyWith<HandoverEntry> get copyWith => _$HandoverEntryCopyWithImpl<HandoverEntry>(this as HandoverEntry, _$identity);

  /// Serializes this HandoverEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as HandoverEntry;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HandoverEntry&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.note, _this.note) || other.note == _this.note)&&(identical(other.mood, _this.mood) || other.mood == _this.mood)&&const DeepCollectionEquality().equals(other.childIds, _this.childIds)&&(identical(other.photoId, _this.photoId) || other.photoId == _this.photoId)&&(identical(other.at, _this.at) || other.at == _this.at)&&(identical(other.byMemberId, _this.byMemberId) || other.byMemberId == _this.byMemberId)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as HandoverEntry;
  return Object.hash(runtimeType,_this.id,_this.kind,_this.note,_this.mood,const DeepCollectionEquality().hash(_this.childIds),_this.photoId,_this.at,_this.byMemberId,_this.createdAt);
}

@override
String toString() {
  final _this = this as HandoverEntry;
  return 'HandoverEntry(id: ${_this.id}, kind: ${_this.kind}, note: ${_this.note}, mood: ${_this.mood}, childIds: ${_this.childIds}, photoId: ${_this.photoId}, at: ${_this.at}, byMemberId: ${_this.byMemberId}, createdAt: ${_this.createdAt})';
}


}

/// @nodoc
abstract mixin class $HandoverEntryCopyWith<$Res>  {
  factory $HandoverEntryCopyWith(HandoverEntry value, $Res Function(HandoverEntry) _then) = _$HandoverEntryCopyWithImpl;
@useResult
$Res call({
@JsonKey(includeToJson: false) String id,@JsonKey(unknownEnumValue: HandoverKind.note) HandoverKind kind, String? note,@JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) HandoverMood? mood, List<String> childIds, String? photoId,@InstantConverter() DateTime at, String byMemberId,@ServerTimestampConverter() DateTime? createdAt
});




}
/// @nodoc
class _$HandoverEntryCopyWithImpl<$Res>
    implements $HandoverEntryCopyWith<$Res> {
  _$HandoverEntryCopyWithImpl(this._self, this._then);

  final HandoverEntry _self;
  final $Res Function(HandoverEntry) _then;

/// Create a copy of HandoverEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? kind = null,Object? note = freezed,Object? mood = freezed,Object? childIds = null,Object? photoId = freezed,Object? at = null,Object? byMemberId = null,Object? createdAt = freezed,}) {
  return _then(HandoverEntry(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as HandoverKind,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,mood: freezed == mood ? _self.mood : mood // ignore: cast_nullable_to_non_nullable
as HandoverMood?,childIds: null == childIds ? _self.childIds : childIds // ignore: cast_nullable_to_non_nullable
as List<String>,photoId: freezed == photoId ? _self.photoId : photoId // ignore: cast_nullable_to_non_nullable
as String?,at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime,byMemberId: null == byMemberId ? _self.byMemberId : byMemberId // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [HandoverEntry].
extension HandoverEntryPatterns on HandoverEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HandoverEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HandoverEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HandoverEntry value)  $default,){
final _that = this;
switch (_that) {
case _HandoverEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HandoverEntry value)?  $default,){
final _that = this;
switch (_that) {
case _HandoverEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id, @JsonKey(unknownEnumValue: HandoverKind.note)  HandoverKind kind,  String? note, @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)  HandoverMood? mood,  List<String> childIds,  String? photoId, @InstantConverter()  DateTime at,  String byMemberId, @ServerTimestampConverter()  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HandoverEntry() when $default != null:
return $default(_that.id,_that.kind,_that.note,_that.mood,_that.childIds,_that.photoId,_that.at,_that.byMemberId,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id, @JsonKey(unknownEnumValue: HandoverKind.note)  HandoverKind kind,  String? note, @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)  HandoverMood? mood,  List<String> childIds,  String? photoId, @InstantConverter()  DateTime at,  String byMemberId, @ServerTimestampConverter()  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _HandoverEntry():
return $default(_that.id,_that.kind,_that.note,_that.mood,_that.childIds,_that.photoId,_that.at,_that.byMemberId,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(includeToJson: false)  String id, @JsonKey(unknownEnumValue: HandoverKind.note)  HandoverKind kind,  String? note, @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)  HandoverMood? mood,  List<String> childIds,  String? photoId, @InstantConverter()  DateTime at,  String byMemberId, @ServerTimestampConverter()  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _HandoverEntry() when $default != null:
return $default(_that.id,_that.kind,_that.note,_that.mood,_that.childIds,_that.photoId,_that.at,_that.byMemberId,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HandoverEntry implements HandoverEntry {
  const _HandoverEntry({@JsonKey(includeToJson: false) required this.id, @JsonKey(unknownEnumValue: HandoverKind.note) required this.kind, this.note, @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) this.mood,  List<String> childIds = const <String>[], this.photoId, @InstantConverter() required this.at, required this.byMemberId, @ServerTimestampConverter() this.createdAt}): _childIds = childIds;
  factory _HandoverEntry.fromJson(Map<String, dynamic> json) => _$HandoverEntryFromJson(json);

@override@JsonKey(includeToJson: false) final  String id;
@override@JsonKey(unknownEnumValue: HandoverKind.note) final  HandoverKind kind;
@override final  String? note;
@override@JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) final  HandoverMood? mood;
 final  List<String> _childIds;
@override@JsonKey() List<String> get childIds {
  if (_childIds is EqualUnmodifiableListView) return _childIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_childIds);
}

@override final  String? photoId;
@override@InstantConverter() final  DateTime at;
@override final  String byMemberId;
@override@ServerTimestampConverter() final  DateTime? createdAt;

/// Create a copy of HandoverEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HandoverEntryCopyWith<_HandoverEntry> get copyWith => __$HandoverEntryCopyWithImpl<_HandoverEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HandoverEntryToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _HandoverEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.note, note) || other.note == note)&&(identical(other.mood, mood) || other.mood == mood)&&const DeepCollectionEquality().equals(other.childIds, _childIds)&&(identical(other.photoId, photoId) || other.photoId == photoId)&&(identical(other.at, at) || other.at == at)&&(identical(other.byMemberId, byMemberId) || other.byMemberId == byMemberId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,kind,note,mood,const DeepCollectionEquality().hash(_childIds),photoId,at,byMemberId,createdAt);
}

@override
String toString() {
    return 'HandoverEntry(id: $id, kind: $kind, note: $note, mood: $mood, childIds: $childIds, photoId: $photoId, at: $at, byMemberId: $byMemberId, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$HandoverEntryCopyWith<$Res> implements $HandoverEntryCopyWith<$Res> {
  factory _$HandoverEntryCopyWith(_HandoverEntry value, $Res Function(_HandoverEntry) _then) = __$HandoverEntryCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(includeToJson: false) String id,@JsonKey(unknownEnumValue: HandoverKind.note) HandoverKind kind, String? note,@JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) HandoverMood? mood, List<String> childIds, String? photoId,@InstantConverter() DateTime at, String byMemberId,@ServerTimestampConverter() DateTime? createdAt
});




}
/// @nodoc
class __$HandoverEntryCopyWithImpl<$Res>
    implements _$HandoverEntryCopyWith<$Res> {
  __$HandoverEntryCopyWithImpl(this._self, this._then);

  final _HandoverEntry _self;
  final $Res Function(_HandoverEntry) _then;

/// Create a copy of HandoverEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? kind = null,Object? note = freezed,Object? mood = freezed,Object? childIds = null,Object? photoId = freezed,Object? at = null,Object? byMemberId = null,Object? createdAt = freezed,}) {
  return _then(_HandoverEntry(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as HandoverKind,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,mood: freezed == mood ? _self.mood : mood // ignore: cast_nullable_to_non_nullable
as HandoverMood?,childIds: null == childIds ? _self._childIds : childIds // ignore: cast_nullable_to_non_nullable
as List<String>,photoId: freezed == photoId ? _self.photoId : photoId // ignore: cast_nullable_to_non_nullable
as String?,at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime,byMemberId: null == byMemberId ? _self.byMemberId : byMemberId // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
