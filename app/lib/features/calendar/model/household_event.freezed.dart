// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'household_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$HouseholdEvent {

@JsonKey(includeToJson: false) String get id; String get title; String? get note;/// The first occurrence's day, in the household's timezone.
@CalendarDateConverter() CalendarDate get date;/// Minutes since midnight where the household lives. Null on both means
/// all day.
 int? get startMinute; int? get endMinute; RecurrenceRule? get recurrence;/// The member profiles it is for — a school run is for the child and the
/// parent driving.
 List<String> get memberIds; String get createdBy;@ServerTimestampConverter() DateTime? get createdAt;
/// Create a copy of HouseholdEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HouseholdEventCopyWith<HouseholdEvent> get copyWith => _$HouseholdEventCopyWithImpl<HouseholdEvent>(this as HouseholdEvent, _$identity);

  /// Serializes this HouseholdEvent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as HouseholdEvent;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HouseholdEvent&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.note, _this.note) || other.note == _this.note)&&(identical(other.date, _this.date) || other.date == _this.date)&&(identical(other.startMinute, _this.startMinute) || other.startMinute == _this.startMinute)&&(identical(other.endMinute, _this.endMinute) || other.endMinute == _this.endMinute)&&(identical(other.recurrence, _this.recurrence) || other.recurrence == _this.recurrence)&&const DeepCollectionEquality().equals(other.memberIds, _this.memberIds)&&(identical(other.createdBy, _this.createdBy) || other.createdBy == _this.createdBy)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as HouseholdEvent;
  return Object.hash(runtimeType,_this.id,_this.title,_this.note,_this.date,_this.startMinute,_this.endMinute,_this.recurrence,const DeepCollectionEquality().hash(_this.memberIds),_this.createdBy,_this.createdAt);
}

@override
String toString() {
  final _this = this as HouseholdEvent;
  return 'HouseholdEvent(id: ${_this.id}, title: ${_this.title}, note: ${_this.note}, date: ${_this.date}, startMinute: ${_this.startMinute}, endMinute: ${_this.endMinute}, recurrence: ${_this.recurrence}, memberIds: ${_this.memberIds}, createdBy: ${_this.createdBy}, createdAt: ${_this.createdAt})';
}


}

/// @nodoc
abstract mixin class $HouseholdEventCopyWith<$Res>  {
  factory $HouseholdEventCopyWith(HouseholdEvent value, $Res Function(HouseholdEvent) _then) = _$HouseholdEventCopyWithImpl;
@useResult
$Res call({
@JsonKey(includeToJson: false) String id, String title, String? note,@CalendarDateConverter() CalendarDate date, int? startMinute, int? endMinute, RecurrenceRule? recurrence, List<String> memberIds, String createdBy,@ServerTimestampConverter() DateTime? createdAt
});


$RecurrenceRuleCopyWith<$Res>? get recurrence;

}
/// @nodoc
class _$HouseholdEventCopyWithImpl<$Res>
    implements $HouseholdEventCopyWith<$Res> {
  _$HouseholdEventCopyWithImpl(this._self, this._then);

  final HouseholdEvent _self;
  final $Res Function(HouseholdEvent) _then;

/// Create a copy of HouseholdEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? note = freezed,Object? date = null,Object? startMinute = freezed,Object? endMinute = freezed,Object? recurrence = freezed,Object? memberIds = null,Object? createdBy = null,Object? createdAt = freezed,}) {
  return _then(HouseholdEvent(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as CalendarDate,startMinute: freezed == startMinute ? _self.startMinute : startMinute // ignore: cast_nullable_to_non_nullable
as int?,endMinute: freezed == endMinute ? _self.endMinute : endMinute // ignore: cast_nullable_to_non_nullable
as int?,recurrence: freezed == recurrence ? _self.recurrence : recurrence // ignore: cast_nullable_to_non_nullable
as RecurrenceRule?,memberIds: null == memberIds ? _self.memberIds : memberIds // ignore: cast_nullable_to_non_nullable
as List<String>,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of HouseholdEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RecurrenceRuleCopyWith<$Res>? get recurrence {
    if (_self.recurrence == null) {
    return null;
  }

  return $RecurrenceRuleCopyWith<$Res>(_self.recurrence!, (value) {
    return _then(_self.copyWith(recurrence: value));
  });
}
}


/// Adds pattern-matching-related methods to [HouseholdEvent].
extension HouseholdEventPatterns on HouseholdEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HouseholdEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HouseholdEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HouseholdEvent value)  $default,){
final _that = this;
switch (_that) {
case _HouseholdEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HouseholdEvent value)?  $default,){
final _that = this;
switch (_that) {
case _HouseholdEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  String title,  String? note, @CalendarDateConverter()  CalendarDate date,  int? startMinute,  int? endMinute,  RecurrenceRule? recurrence,  List<String> memberIds,  String createdBy, @ServerTimestampConverter()  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HouseholdEvent() when $default != null:
return $default(_that.id,_that.title,_that.note,_that.date,_that.startMinute,_that.endMinute,_that.recurrence,_that.memberIds,_that.createdBy,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  String title,  String? note, @CalendarDateConverter()  CalendarDate date,  int? startMinute,  int? endMinute,  RecurrenceRule? recurrence,  List<String> memberIds,  String createdBy, @ServerTimestampConverter()  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _HouseholdEvent():
return $default(_that.id,_that.title,_that.note,_that.date,_that.startMinute,_that.endMinute,_that.recurrence,_that.memberIds,_that.createdBy,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(includeToJson: false)  String id,  String title,  String? note, @CalendarDateConverter()  CalendarDate date,  int? startMinute,  int? endMinute,  RecurrenceRule? recurrence,  List<String> memberIds,  String createdBy, @ServerTimestampConverter()  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _HouseholdEvent() when $default != null:
return $default(_that.id,_that.title,_that.note,_that.date,_that.startMinute,_that.endMinute,_that.recurrence,_that.memberIds,_that.createdBy,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HouseholdEvent extends HouseholdEvent {
  const _HouseholdEvent({@JsonKey(includeToJson: false) required this.id, required this.title, this.note, @CalendarDateConverter() required this.date, this.startMinute, this.endMinute, this.recurrence,  List<String> memberIds = const <String>[], required this.createdBy, @ServerTimestampConverter() this.createdAt}): _memberIds = memberIds,super._();
  factory _HouseholdEvent.fromJson(Map<String, dynamic> json) => _$HouseholdEventFromJson(json);

@override@JsonKey(includeToJson: false) final  String id;
@override final  String title;
@override final  String? note;
/// The first occurrence's day, in the household's timezone.
@override@CalendarDateConverter() final  CalendarDate date;
/// Minutes since midnight where the household lives. Null on both means
/// all day.
@override final  int? startMinute;
@override final  int? endMinute;
@override final  RecurrenceRule? recurrence;
/// The member profiles it is for — a school run is for the child and the
/// parent driving.
 final  List<String> _memberIds;
/// The member profiles it is for — a school run is for the child and the
/// parent driving.
@override@JsonKey() List<String> get memberIds {
  if (_memberIds is EqualUnmodifiableListView) return _memberIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_memberIds);
}

@override final  String createdBy;
@override@ServerTimestampConverter() final  DateTime? createdAt;

/// Create a copy of HouseholdEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HouseholdEventCopyWith<_HouseholdEvent> get copyWith => __$HouseholdEventCopyWithImpl<_HouseholdEvent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HouseholdEventToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _HouseholdEvent&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.note, note) || other.note == note)&&(identical(other.date, date) || other.date == date)&&(identical(other.startMinute, startMinute) || other.startMinute == startMinute)&&(identical(other.endMinute, endMinute) || other.endMinute == endMinute)&&(identical(other.recurrence, recurrence) || other.recurrence == recurrence)&&const DeepCollectionEquality().equals(other.memberIds, _memberIds)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,title,note,date,startMinute,endMinute,recurrence,const DeepCollectionEquality().hash(_memberIds),createdBy,createdAt);
}

@override
String toString() {
    return 'HouseholdEvent(id: $id, title: $title, note: $note, date: $date, startMinute: $startMinute, endMinute: $endMinute, recurrence: $recurrence, memberIds: $memberIds, createdBy: $createdBy, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$HouseholdEventCopyWith<$Res> implements $HouseholdEventCopyWith<$Res> {
  factory _$HouseholdEventCopyWith(_HouseholdEvent value, $Res Function(_HouseholdEvent) _then) = __$HouseholdEventCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(includeToJson: false) String id, String title, String? note,@CalendarDateConverter() CalendarDate date, int? startMinute, int? endMinute, RecurrenceRule? recurrence, List<String> memberIds, String createdBy,@ServerTimestampConverter() DateTime? createdAt
});


@override $RecurrenceRuleCopyWith<$Res>? get recurrence;

}
/// @nodoc
class __$HouseholdEventCopyWithImpl<$Res>
    implements _$HouseholdEventCopyWith<$Res> {
  __$HouseholdEventCopyWithImpl(this._self, this._then);

  final _HouseholdEvent _self;
  final $Res Function(_HouseholdEvent) _then;

/// Create a copy of HouseholdEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? note = freezed,Object? date = null,Object? startMinute = freezed,Object? endMinute = freezed,Object? recurrence = freezed,Object? memberIds = null,Object? createdBy = null,Object? createdAt = freezed,}) {
  return _then(_HouseholdEvent(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as CalendarDate,startMinute: freezed == startMinute ? _self.startMinute : startMinute // ignore: cast_nullable_to_non_nullable
as int?,endMinute: freezed == endMinute ? _self.endMinute : endMinute // ignore: cast_nullable_to_non_nullable
as int?,recurrence: freezed == recurrence ? _self.recurrence : recurrence // ignore: cast_nullable_to_non_nullable
as RecurrenceRule?,memberIds: null == memberIds ? _self._memberIds : memberIds // ignore: cast_nullable_to_non_nullable
as List<String>,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of HouseholdEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RecurrenceRuleCopyWith<$Res>? get recurrence {
    if (_self.recurrence == null) {
    return null;
  }

  return $RecurrenceRuleCopyWith<$Res>(_self.recurrence!, (value) {
    return _then(_self.copyWith(recurrence: value));
  });
}
}

// dart format on
