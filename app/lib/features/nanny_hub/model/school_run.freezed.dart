// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'school_run.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SchoolRun {

@JsonKey(includeToJson: false) String get id; String get childId;/// ISO weekday: Monday is 1, Sunday is 7.
 int get weekday; String? get personId; String? get memberId;/// The wall-clock minute in the household's zone (`ENG-21`).
 int? get atMinute;/// "Oakwood Primary, the side gate".
 String? get place; String get updatedBy;@ServerTimestampConverter() DateTime? get updatedAt;
/// Create a copy of SchoolRun
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SchoolRunCopyWith<SchoolRun> get copyWith => _$SchoolRunCopyWithImpl<SchoolRun>(this as SchoolRun, _$identity);

  /// Serializes this SchoolRun to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SchoolRun;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SchoolRun&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.childId, _this.childId) || other.childId == _this.childId)&&(identical(other.weekday, _this.weekday) || other.weekday == _this.weekday)&&(identical(other.personId, _this.personId) || other.personId == _this.personId)&&(identical(other.memberId, _this.memberId) || other.memberId == _this.memberId)&&(identical(other.atMinute, _this.atMinute) || other.atMinute == _this.atMinute)&&(identical(other.place, _this.place) || other.place == _this.place)&&(identical(other.updatedBy, _this.updatedBy) || other.updatedBy == _this.updatedBy)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SchoolRun;
  return Object.hash(runtimeType,_this.id,_this.childId,_this.weekday,_this.personId,_this.memberId,_this.atMinute,_this.place,_this.updatedBy,_this.updatedAt);
}

@override
String toString() {
  final _this = this as SchoolRun;
  return 'SchoolRun(id: ${_this.id}, childId: ${_this.childId}, weekday: ${_this.weekday}, personId: ${_this.personId}, memberId: ${_this.memberId}, atMinute: ${_this.atMinute}, place: ${_this.place}, updatedBy: ${_this.updatedBy}, updatedAt: ${_this.updatedAt})';
}


}

/// @nodoc
abstract mixin class $SchoolRunCopyWith<$Res>  {
  factory $SchoolRunCopyWith(SchoolRun value, $Res Function(SchoolRun) _then) = _$SchoolRunCopyWithImpl;
@useResult
$Res call({
@JsonKey(includeToJson: false) String id, String childId, int weekday, String? personId, String? memberId, int? atMinute, String? place, String updatedBy,@ServerTimestampConverter() DateTime? updatedAt
});




}
/// @nodoc
class _$SchoolRunCopyWithImpl<$Res>
    implements $SchoolRunCopyWith<$Res> {
  _$SchoolRunCopyWithImpl(this._self, this._then);

  final SchoolRun _self;
  final $Res Function(SchoolRun) _then;

/// Create a copy of SchoolRun
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? childId = null,Object? weekday = null,Object? personId = freezed,Object? memberId = freezed,Object? atMinute = freezed,Object? place = freezed,Object? updatedBy = null,Object? updatedAt = freezed,}) {
  return _then(SchoolRun(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,childId: null == childId ? _self.childId : childId // ignore: cast_nullable_to_non_nullable
as String,weekday: null == weekday ? _self.weekday : weekday // ignore: cast_nullable_to_non_nullable
as int,personId: freezed == personId ? _self.personId : personId // ignore: cast_nullable_to_non_nullable
as String?,memberId: freezed == memberId ? _self.memberId : memberId // ignore: cast_nullable_to_non_nullable
as String?,atMinute: freezed == atMinute ? _self.atMinute : atMinute // ignore: cast_nullable_to_non_nullable
as int?,place: freezed == place ? _self.place : place // ignore: cast_nullable_to_non_nullable
as String?,updatedBy: null == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [SchoolRun].
extension SchoolRunPatterns on SchoolRun {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SchoolRun value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SchoolRun() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SchoolRun value)  $default,){
final _that = this;
switch (_that) {
case _SchoolRun():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SchoolRun value)?  $default,){
final _that = this;
switch (_that) {
case _SchoolRun() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  String childId,  int weekday,  String? personId,  String? memberId,  int? atMinute,  String? place,  String updatedBy, @ServerTimestampConverter()  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SchoolRun() when $default != null:
return $default(_that.id,_that.childId,_that.weekday,_that.personId,_that.memberId,_that.atMinute,_that.place,_that.updatedBy,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  String childId,  int weekday,  String? personId,  String? memberId,  int? atMinute,  String? place,  String updatedBy, @ServerTimestampConverter()  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _SchoolRun():
return $default(_that.id,_that.childId,_that.weekday,_that.personId,_that.memberId,_that.atMinute,_that.place,_that.updatedBy,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(includeToJson: false)  String id,  String childId,  int weekday,  String? personId,  String? memberId,  int? atMinute,  String? place,  String updatedBy, @ServerTimestampConverter()  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _SchoolRun() when $default != null:
return $default(_that.id,_that.childId,_that.weekday,_that.personId,_that.memberId,_that.atMinute,_that.place,_that.updatedBy,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SchoolRun extends SchoolRun {
  const _SchoolRun({@JsonKey(includeToJson: false) required this.id, required this.childId, required this.weekday, this.personId, this.memberId, this.atMinute, this.place, required this.updatedBy, @ServerTimestampConverter() this.updatedAt}): super._();
  factory _SchoolRun.fromJson(Map<String, dynamic> json) => _$SchoolRunFromJson(json);

@override@JsonKey(includeToJson: false) final  String id;
@override final  String childId;
/// ISO weekday: Monday is 1, Sunday is 7.
@override final  int weekday;
@override final  String? personId;
@override final  String? memberId;
/// The wall-clock minute in the household's zone (`ENG-21`).
@override final  int? atMinute;
/// "Oakwood Primary, the side gate".
@override final  String? place;
@override final  String updatedBy;
@override@ServerTimestampConverter() final  DateTime? updatedAt;

/// Create a copy of SchoolRun
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SchoolRunCopyWith<_SchoolRun> get copyWith => __$SchoolRunCopyWithImpl<_SchoolRun>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SchoolRunToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SchoolRun&&(identical(other.id, id) || other.id == id)&&(identical(other.childId, childId) || other.childId == childId)&&(identical(other.weekday, weekday) || other.weekday == weekday)&&(identical(other.personId, personId) || other.personId == personId)&&(identical(other.memberId, memberId) || other.memberId == memberId)&&(identical(other.atMinute, atMinute) || other.atMinute == atMinute)&&(identical(other.place, place) || other.place == place)&&(identical(other.updatedBy, updatedBy) || other.updatedBy == updatedBy)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,childId,weekday,personId,memberId,atMinute,place,updatedBy,updatedAt);
}

@override
String toString() {
    return 'SchoolRun(id: $id, childId: $childId, weekday: $weekday, personId: $personId, memberId: $memberId, atMinute: $atMinute, place: $place, updatedBy: $updatedBy, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$SchoolRunCopyWith<$Res> implements $SchoolRunCopyWith<$Res> {
  factory _$SchoolRunCopyWith(_SchoolRun value, $Res Function(_SchoolRun) _then) = __$SchoolRunCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(includeToJson: false) String id, String childId, int weekday, String? personId, String? memberId, int? atMinute, String? place, String updatedBy,@ServerTimestampConverter() DateTime? updatedAt
});




}
/// @nodoc
class __$SchoolRunCopyWithImpl<$Res>
    implements _$SchoolRunCopyWith<$Res> {
  __$SchoolRunCopyWithImpl(this._self, this._then);

  final _SchoolRun _self;
  final $Res Function(_SchoolRun) _then;

/// Create a copy of SchoolRun
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? childId = null,Object? weekday = null,Object? personId = freezed,Object? memberId = freezed,Object? atMinute = freezed,Object? place = freezed,Object? updatedBy = null,Object? updatedAt = freezed,}) {
  return _then(_SchoolRun(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,childId: null == childId ? _self.childId : childId // ignore: cast_nullable_to_non_nullable
as String,weekday: null == weekday ? _self.weekday : weekday // ignore: cast_nullable_to_non_nullable
as int,personId: freezed == personId ? _self.personId : personId // ignore: cast_nullable_to_non_nullable
as String?,memberId: freezed == memberId ? _self.memberId : memberId // ignore: cast_nullable_to_non_nullable
as String?,atMinute: freezed == atMinute ? _self.atMinute : atMinute // ignore: cast_nullable_to_non_nullable
as int?,place: freezed == place ? _self.place : place // ignore: cast_nullable_to_non_nullable
as String?,updatedBy: null == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
