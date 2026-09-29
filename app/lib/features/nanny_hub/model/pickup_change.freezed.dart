// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pickup_change.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PickupChange {

@JsonKey(includeToJson: false) String get id; String get childId;@CalendarDateConverter() CalendarDate get date; String? get personId; String? get memberId; int? get atMinute; String? get note; String get updatedBy;@ServerTimestampConverter() DateTime? get updatedAt;
/// Create a copy of PickupChange
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PickupChangeCopyWith<PickupChange> get copyWith => _$PickupChangeCopyWithImpl<PickupChange>(this as PickupChange, _$identity);

  /// Serializes this PickupChange to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PickupChange;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PickupChange&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.childId, _this.childId) || other.childId == _this.childId)&&(identical(other.date, _this.date) || other.date == _this.date)&&(identical(other.personId, _this.personId) || other.personId == _this.personId)&&(identical(other.memberId, _this.memberId) || other.memberId == _this.memberId)&&(identical(other.atMinute, _this.atMinute) || other.atMinute == _this.atMinute)&&(identical(other.note, _this.note) || other.note == _this.note)&&(identical(other.updatedBy, _this.updatedBy) || other.updatedBy == _this.updatedBy)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PickupChange;
  return Object.hash(runtimeType,_this.id,_this.childId,_this.date,_this.personId,_this.memberId,_this.atMinute,_this.note,_this.updatedBy,_this.updatedAt);
}

@override
String toString() {
  final _this = this as PickupChange;
  return 'PickupChange(id: ${_this.id}, childId: ${_this.childId}, date: ${_this.date}, personId: ${_this.personId}, memberId: ${_this.memberId}, atMinute: ${_this.atMinute}, note: ${_this.note}, updatedBy: ${_this.updatedBy}, updatedAt: ${_this.updatedAt})';
}


}

/// @nodoc
abstract mixin class $PickupChangeCopyWith<$Res>  {
  factory $PickupChangeCopyWith(PickupChange value, $Res Function(PickupChange) _then) = _$PickupChangeCopyWithImpl;
@useResult
$Res call({
@JsonKey(includeToJson: false) String id, String childId,@CalendarDateConverter() CalendarDate date, String? personId, String? memberId, int? atMinute, String? note, String updatedBy,@ServerTimestampConverter() DateTime? updatedAt
});




}
/// @nodoc
class _$PickupChangeCopyWithImpl<$Res>
    implements $PickupChangeCopyWith<$Res> {
  _$PickupChangeCopyWithImpl(this._self, this._then);

  final PickupChange _self;
  final $Res Function(PickupChange) _then;

/// Create a copy of PickupChange
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? childId = null,Object? date = null,Object? personId = freezed,Object? memberId = freezed,Object? atMinute = freezed,Object? note = freezed,Object? updatedBy = null,Object? updatedAt = freezed,}) {
  return _then(PickupChange(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,childId: null == childId ? _self.childId : childId // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as CalendarDate,personId: freezed == personId ? _self.personId : personId // ignore: cast_nullable_to_non_nullable
as String?,memberId: freezed == memberId ? _self.memberId : memberId // ignore: cast_nullable_to_non_nullable
as String?,atMinute: freezed == atMinute ? _self.atMinute : atMinute // ignore: cast_nullable_to_non_nullable
as int?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,updatedBy: null == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [PickupChange].
extension PickupChangePatterns on PickupChange {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PickupChange value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PickupChange() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PickupChange value)  $default,){
final _that = this;
switch (_that) {
case _PickupChange():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PickupChange value)?  $default,){
final _that = this;
switch (_that) {
case _PickupChange() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  String childId, @CalendarDateConverter()  CalendarDate date,  String? personId,  String? memberId,  int? atMinute,  String? note,  String updatedBy, @ServerTimestampConverter()  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PickupChange() when $default != null:
return $default(_that.id,_that.childId,_that.date,_that.personId,_that.memberId,_that.atMinute,_that.note,_that.updatedBy,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  String childId, @CalendarDateConverter()  CalendarDate date,  String? personId,  String? memberId,  int? atMinute,  String? note,  String updatedBy, @ServerTimestampConverter()  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _PickupChange():
return $default(_that.id,_that.childId,_that.date,_that.personId,_that.memberId,_that.atMinute,_that.note,_that.updatedBy,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(includeToJson: false)  String id,  String childId, @CalendarDateConverter()  CalendarDate date,  String? personId,  String? memberId,  int? atMinute,  String? note,  String updatedBy, @ServerTimestampConverter()  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _PickupChange() when $default != null:
return $default(_that.id,_that.childId,_that.date,_that.personId,_that.memberId,_that.atMinute,_that.note,_that.updatedBy,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PickupChange extends PickupChange {
  const _PickupChange({@JsonKey(includeToJson: false) required this.id, required this.childId, @CalendarDateConverter() required this.date, this.personId, this.memberId, this.atMinute, this.note, required this.updatedBy, @ServerTimestampConverter() this.updatedAt}): super._();
  factory _PickupChange.fromJson(Map<String, dynamic> json) => _$PickupChangeFromJson(json);

@override@JsonKey(includeToJson: false) final  String id;
@override final  String childId;
@override@CalendarDateConverter() final  CalendarDate date;
@override final  String? personId;
@override final  String? memberId;
@override final  int? atMinute;
@override final  String? note;
@override final  String updatedBy;
@override@ServerTimestampConverter() final  DateTime? updatedAt;

/// Create a copy of PickupChange
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PickupChangeCopyWith<_PickupChange> get copyWith => __$PickupChangeCopyWithImpl<_PickupChange>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PickupChangeToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PickupChange&&(identical(other.id, id) || other.id == id)&&(identical(other.childId, childId) || other.childId == childId)&&(identical(other.date, date) || other.date == date)&&(identical(other.personId, personId) || other.personId == personId)&&(identical(other.memberId, memberId) || other.memberId == memberId)&&(identical(other.atMinute, atMinute) || other.atMinute == atMinute)&&(identical(other.note, note) || other.note == note)&&(identical(other.updatedBy, updatedBy) || other.updatedBy == updatedBy)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,childId,date,personId,memberId,atMinute,note,updatedBy,updatedAt);
}

@override
String toString() {
    return 'PickupChange(id: $id, childId: $childId, date: $date, personId: $personId, memberId: $memberId, atMinute: $atMinute, note: $note, updatedBy: $updatedBy, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$PickupChangeCopyWith<$Res> implements $PickupChangeCopyWith<$Res> {
  factory _$PickupChangeCopyWith(_PickupChange value, $Res Function(_PickupChange) _then) = __$PickupChangeCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(includeToJson: false) String id, String childId,@CalendarDateConverter() CalendarDate date, String? personId, String? memberId, int? atMinute, String? note, String updatedBy,@ServerTimestampConverter() DateTime? updatedAt
});




}
/// @nodoc
class __$PickupChangeCopyWithImpl<$Res>
    implements _$PickupChangeCopyWith<$Res> {
  __$PickupChangeCopyWithImpl(this._self, this._then);

  final _PickupChange _self;
  final $Res Function(_PickupChange) _then;

/// Create a copy of PickupChange
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? childId = null,Object? date = null,Object? personId = freezed,Object? memberId = freezed,Object? atMinute = freezed,Object? note = freezed,Object? updatedBy = null,Object? updatedAt = freezed,}) {
  return _then(_PickupChange(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,childId: null == childId ? _self.childId : childId // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as CalendarDate,personId: freezed == personId ? _self.personId : personId // ignore: cast_nullable_to_non_nullable
as String?,memberId: freezed == memberId ? _self.memberId : memberId // ignore: cast_nullable_to_non_nullable
as String?,atMinute: freezed == atMinute ? _self.atMinute : atMinute // ignore: cast_nullable_to_non_nullable
as int?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,updatedBy: null == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
