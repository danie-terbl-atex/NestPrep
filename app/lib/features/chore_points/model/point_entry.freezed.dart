// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'point_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PointEntry {

@JsonKey(includeToJson: false) String get id; String get memberId;/// Positive when stars were earned or returned, negative when spent or
/// taken back.
 int get delta;@JsonKey(unknownEnumValue: EntryKind.chore) EntryKind get kind;/// The completion or reward request the line is about.
 String get sourceId; String get title;@NullableTimestampConverter() DateTime? get at;
/// Create a copy of PointEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PointEntryCopyWith<PointEntry> get copyWith => _$PointEntryCopyWithImpl<PointEntry>(this as PointEntry, _$identity);

  /// Serializes this PointEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PointEntry;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PointEntry&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.memberId, _this.memberId) || other.memberId == _this.memberId)&&(identical(other.delta, _this.delta) || other.delta == _this.delta)&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.sourceId, _this.sourceId) || other.sourceId == _this.sourceId)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.at, _this.at) || other.at == _this.at));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PointEntry;
  return Object.hash(runtimeType,_this.id,_this.memberId,_this.delta,_this.kind,_this.sourceId,_this.title,_this.at);
}

@override
String toString() {
  final _this = this as PointEntry;
  return 'PointEntry(id: ${_this.id}, memberId: ${_this.memberId}, delta: ${_this.delta}, kind: ${_this.kind}, sourceId: ${_this.sourceId}, title: ${_this.title}, at: ${_this.at})';
}


}

/// @nodoc
abstract mixin class $PointEntryCopyWith<$Res>  {
  factory $PointEntryCopyWith(PointEntry value, $Res Function(PointEntry) _then) = _$PointEntryCopyWithImpl;
@useResult
$Res call({
@JsonKey(includeToJson: false) String id, String memberId, int delta,@JsonKey(unknownEnumValue: EntryKind.chore) EntryKind kind, String sourceId, String title,@NullableTimestampConverter() DateTime? at
});




}
/// @nodoc
class _$PointEntryCopyWithImpl<$Res>
    implements $PointEntryCopyWith<$Res> {
  _$PointEntryCopyWithImpl(this._self, this._then);

  final PointEntry _self;
  final $Res Function(PointEntry) _then;

/// Create a copy of PointEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? memberId = null,Object? delta = null,Object? kind = null,Object? sourceId = null,Object? title = null,Object? at = freezed,}) {
  return _then(PointEntry(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,memberId: null == memberId ? _self.memberId : memberId // ignore: cast_nullable_to_non_nullable
as String,delta: null == delta ? _self.delta : delta // ignore: cast_nullable_to_non_nullable
as int,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as EntryKind,sourceId: null == sourceId ? _self.sourceId : sourceId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,at: freezed == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [PointEntry].
extension PointEntryPatterns on PointEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PointEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PointEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PointEntry value)  $default,){
final _that = this;
switch (_that) {
case _PointEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PointEntry value)?  $default,){
final _that = this;
switch (_that) {
case _PointEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  String memberId,  int delta, @JsonKey(unknownEnumValue: EntryKind.chore)  EntryKind kind,  String sourceId,  String title, @NullableTimestampConverter()  DateTime? at)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PointEntry() when $default != null:
return $default(_that.id,_that.memberId,_that.delta,_that.kind,_that.sourceId,_that.title,_that.at);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  String memberId,  int delta, @JsonKey(unknownEnumValue: EntryKind.chore)  EntryKind kind,  String sourceId,  String title, @NullableTimestampConverter()  DateTime? at)  $default,) {final _that = this;
switch (_that) {
case _PointEntry():
return $default(_that.id,_that.memberId,_that.delta,_that.kind,_that.sourceId,_that.title,_that.at);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(includeToJson: false)  String id,  String memberId,  int delta, @JsonKey(unknownEnumValue: EntryKind.chore)  EntryKind kind,  String sourceId,  String title, @NullableTimestampConverter()  DateTime? at)?  $default,) {final _that = this;
switch (_that) {
case _PointEntry() when $default != null:
return $default(_that.id,_that.memberId,_that.delta,_that.kind,_that.sourceId,_that.title,_that.at);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PointEntry extends PointEntry {
  const _PointEntry({@JsonKey(includeToJson: false) required this.id, required this.memberId, required this.delta, @JsonKey(unknownEnumValue: EntryKind.chore) required this.kind, required this.sourceId, required this.title, @NullableTimestampConverter() this.at}): super._();
  factory _PointEntry.fromJson(Map<String, dynamic> json) => _$PointEntryFromJson(json);

@override@JsonKey(includeToJson: false) final  String id;
@override final  String memberId;
/// Positive when stars were earned or returned, negative when spent or
/// taken back.
@override final  int delta;
@override@JsonKey(unknownEnumValue: EntryKind.chore) final  EntryKind kind;
/// The completion or reward request the line is about.
@override final  String sourceId;
@override final  String title;
@override@NullableTimestampConverter() final  DateTime? at;

/// Create a copy of PointEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PointEntryCopyWith<_PointEntry> get copyWith => __$PointEntryCopyWithImpl<_PointEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PointEntryToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PointEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.memberId, memberId) || other.memberId == memberId)&&(identical(other.delta, delta) || other.delta == delta)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.sourceId, sourceId) || other.sourceId == sourceId)&&(identical(other.title, title) || other.title == title)&&(identical(other.at, at) || other.at == at));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,memberId,delta,kind,sourceId,title,at);
}

@override
String toString() {
    return 'PointEntry(id: $id, memberId: $memberId, delta: $delta, kind: $kind, sourceId: $sourceId, title: $title, at: $at)';
}


}

/// @nodoc
abstract mixin class _$PointEntryCopyWith<$Res> implements $PointEntryCopyWith<$Res> {
  factory _$PointEntryCopyWith(_PointEntry value, $Res Function(_PointEntry) _then) = __$PointEntryCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(includeToJson: false) String id, String memberId, int delta,@JsonKey(unknownEnumValue: EntryKind.chore) EntryKind kind, String sourceId, String title,@NullableTimestampConverter() DateTime? at
});




}
/// @nodoc
class __$PointEntryCopyWithImpl<$Res>
    implements _$PointEntryCopyWith<$Res> {
  __$PointEntryCopyWithImpl(this._self, this._then);

  final _PointEntry _self;
  final $Res Function(_PointEntry) _then;

/// Create a copy of PointEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? memberId = null,Object? delta = null,Object? kind = null,Object? sourceId = null,Object? title = null,Object? at = freezed,}) {
  return _then(_PointEntry(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,memberId: null == memberId ? _self.memberId : memberId // ignore: cast_nullable_to_non_nullable
as String,delta: null == delta ? _self.delta : delta // ignore: cast_nullable_to_non_nullable
as int,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as EntryKind,sourceId: null == sourceId ? _self.sourceId : sourceId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,at: freezed == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
