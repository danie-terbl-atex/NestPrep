// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'room_routine.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RoomRoutine {

@JsonKey(includeToJson: false) String get id; String get name; String get roomId;@JsonKey(unknownEnumValue: RoutineCadence.daily) RoutineCadence get cadence; List<JobStep> get items;/// The member profile who does it — claimed or not. What `own` means.
 String get helperId;@CalendarDateConverter() CalendarDate get firstDate; RecurrenceRule? get recurrence; String get createdBy;@ServerTimestampConverter() DateTime? get createdAt;
/// Create a copy of RoomRoutine
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RoomRoutineCopyWith<RoomRoutine> get copyWith => _$RoomRoutineCopyWithImpl<RoomRoutine>(this as RoomRoutine, _$identity);

  /// Serializes this RoomRoutine to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as RoomRoutine;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RoomRoutine&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.roomId, _this.roomId) || other.roomId == _this.roomId)&&(identical(other.cadence, _this.cadence) || other.cadence == _this.cadence)&&const DeepCollectionEquality().equals(other.items, _this.items)&&(identical(other.helperId, _this.helperId) || other.helperId == _this.helperId)&&(identical(other.firstDate, _this.firstDate) || other.firstDate == _this.firstDate)&&(identical(other.recurrence, _this.recurrence) || other.recurrence == _this.recurrence)&&(identical(other.createdBy, _this.createdBy) || other.createdBy == _this.createdBy)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as RoomRoutine;
  return Object.hash(runtimeType,_this.id,_this.name,_this.roomId,_this.cadence,const DeepCollectionEquality().hash(_this.items),_this.helperId,_this.firstDate,_this.recurrence,_this.createdBy,_this.createdAt);
}

@override
String toString() {
  final _this = this as RoomRoutine;
  return 'RoomRoutine(id: ${_this.id}, name: ${_this.name}, roomId: ${_this.roomId}, cadence: ${_this.cadence}, items: ${_this.items}, helperId: ${_this.helperId}, firstDate: ${_this.firstDate}, recurrence: ${_this.recurrence}, createdBy: ${_this.createdBy}, createdAt: ${_this.createdAt})';
}


}

/// @nodoc
abstract mixin class $RoomRoutineCopyWith<$Res>  {
  factory $RoomRoutineCopyWith(RoomRoutine value, $Res Function(RoomRoutine) _then) = _$RoomRoutineCopyWithImpl;
@useResult
$Res call({
@JsonKey(includeToJson: false) String id, String name, String roomId,@JsonKey(unknownEnumValue: RoutineCadence.daily) RoutineCadence cadence, List<JobStep> items, String helperId,@CalendarDateConverter() CalendarDate firstDate, RecurrenceRule? recurrence, String createdBy,@ServerTimestampConverter() DateTime? createdAt
});


$RecurrenceRuleCopyWith<$Res>? get recurrence;

}
/// @nodoc
class _$RoomRoutineCopyWithImpl<$Res>
    implements $RoomRoutineCopyWith<$Res> {
  _$RoomRoutineCopyWithImpl(this._self, this._then);

  final RoomRoutine _self;
  final $Res Function(RoomRoutine) _then;

/// Create a copy of RoomRoutine
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? roomId = null,Object? cadence = null,Object? items = null,Object? helperId = null,Object? firstDate = null,Object? recurrence = freezed,Object? createdBy = null,Object? createdAt = freezed,}) {
  return _then(RoomRoutine(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,roomId: null == roomId ? _self.roomId : roomId // ignore: cast_nullable_to_non_nullable
as String,cadence: null == cadence ? _self.cadence : cadence // ignore: cast_nullable_to_non_nullable
as RoutineCadence,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<JobStep>,helperId: null == helperId ? _self.helperId : helperId // ignore: cast_nullable_to_non_nullable
as String,firstDate: null == firstDate ? _self.firstDate : firstDate // ignore: cast_nullable_to_non_nullable
as CalendarDate,recurrence: freezed == recurrence ? _self.recurrence : recurrence // ignore: cast_nullable_to_non_nullable
as RecurrenceRule?,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of RoomRoutine
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


/// Adds pattern-matching-related methods to [RoomRoutine].
extension RoomRoutinePatterns on RoomRoutine {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RoomRoutine value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RoomRoutine() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RoomRoutine value)  $default,){
final _that = this;
switch (_that) {
case _RoomRoutine():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RoomRoutine value)?  $default,){
final _that = this;
switch (_that) {
case _RoomRoutine() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  String name,  String roomId, @JsonKey(unknownEnumValue: RoutineCadence.daily)  RoutineCadence cadence,  List<JobStep> items,  String helperId, @CalendarDateConverter()  CalendarDate firstDate,  RecurrenceRule? recurrence,  String createdBy, @ServerTimestampConverter()  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RoomRoutine() when $default != null:
return $default(_that.id,_that.name,_that.roomId,_that.cadence,_that.items,_that.helperId,_that.firstDate,_that.recurrence,_that.createdBy,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  String name,  String roomId, @JsonKey(unknownEnumValue: RoutineCadence.daily)  RoutineCadence cadence,  List<JobStep> items,  String helperId, @CalendarDateConverter()  CalendarDate firstDate,  RecurrenceRule? recurrence,  String createdBy, @ServerTimestampConverter()  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _RoomRoutine():
return $default(_that.id,_that.name,_that.roomId,_that.cadence,_that.items,_that.helperId,_that.firstDate,_that.recurrence,_that.createdBy,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(includeToJson: false)  String id,  String name,  String roomId, @JsonKey(unknownEnumValue: RoutineCadence.daily)  RoutineCadence cadence,  List<JobStep> items,  String helperId, @CalendarDateConverter()  CalendarDate firstDate,  RecurrenceRule? recurrence,  String createdBy, @ServerTimestampConverter()  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _RoomRoutine() when $default != null:
return $default(_that.id,_that.name,_that.roomId,_that.cadence,_that.items,_that.helperId,_that.firstDate,_that.recurrence,_that.createdBy,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RoomRoutine extends RoomRoutine {
  const _RoomRoutine({@JsonKey(includeToJson: false) required this.id, required this.name, required this.roomId, @JsonKey(unknownEnumValue: RoutineCadence.daily) required this.cadence,  List<JobStep> items = const <JobStep>[], required this.helperId, @CalendarDateConverter() required this.firstDate, this.recurrence, required this.createdBy, @ServerTimestampConverter() this.createdAt}): _items = items,super._();
  factory _RoomRoutine.fromJson(Map<String, dynamic> json) => _$RoomRoutineFromJson(json);

@override@JsonKey(includeToJson: false) final  String id;
@override final  String name;
@override final  String roomId;
@override@JsonKey(unknownEnumValue: RoutineCadence.daily) final  RoutineCadence cadence;
 final  List<JobStep> _items;
@override@JsonKey() List<JobStep> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

/// The member profile who does it — claimed or not. What `own` means.
@override final  String helperId;
@override@CalendarDateConverter() final  CalendarDate firstDate;
@override final  RecurrenceRule? recurrence;
@override final  String createdBy;
@override@ServerTimestampConverter() final  DateTime? createdAt;

/// Create a copy of RoomRoutine
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RoomRoutineCopyWith<_RoomRoutine> get copyWith => __$RoomRoutineCopyWithImpl<_RoomRoutine>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RoomRoutineToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RoomRoutine&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.roomId, roomId) || other.roomId == roomId)&&(identical(other.cadence, cadence) || other.cadence == cadence)&&const DeepCollectionEquality().equals(other.items, _items)&&(identical(other.helperId, helperId) || other.helperId == helperId)&&(identical(other.firstDate, firstDate) || other.firstDate == firstDate)&&(identical(other.recurrence, recurrence) || other.recurrence == recurrence)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,roomId,cadence,const DeepCollectionEquality().hash(_items),helperId,firstDate,recurrence,createdBy,createdAt);
}

@override
String toString() {
    return 'RoomRoutine(id: $id, name: $name, roomId: $roomId, cadence: $cadence, items: $items, helperId: $helperId, firstDate: $firstDate, recurrence: $recurrence, createdBy: $createdBy, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$RoomRoutineCopyWith<$Res> implements $RoomRoutineCopyWith<$Res> {
  factory _$RoomRoutineCopyWith(_RoomRoutine value, $Res Function(_RoomRoutine) _then) = __$RoomRoutineCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(includeToJson: false) String id, String name, String roomId,@JsonKey(unknownEnumValue: RoutineCadence.daily) RoutineCadence cadence, List<JobStep> items, String helperId,@CalendarDateConverter() CalendarDate firstDate, RecurrenceRule? recurrence, String createdBy,@ServerTimestampConverter() DateTime? createdAt
});


@override $RecurrenceRuleCopyWith<$Res>? get recurrence;

}
/// @nodoc
class __$RoomRoutineCopyWithImpl<$Res>
    implements _$RoomRoutineCopyWith<$Res> {
  __$RoomRoutineCopyWithImpl(this._self, this._then);

  final _RoomRoutine _self;
  final $Res Function(_RoomRoutine) _then;

/// Create a copy of RoomRoutine
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? roomId = null,Object? cadence = null,Object? items = null,Object? helperId = null,Object? firstDate = null,Object? recurrence = freezed,Object? createdBy = null,Object? createdAt = freezed,}) {
  return _then(_RoomRoutine(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,roomId: null == roomId ? _self.roomId : roomId // ignore: cast_nullable_to_non_nullable
as String,cadence: null == cadence ? _self.cadence : cadence // ignore: cast_nullable_to_non_nullable
as RoutineCadence,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<JobStep>,helperId: null == helperId ? _self.helperId : helperId // ignore: cast_nullable_to_non_nullable
as String,firstDate: null == firstDate ? _self.firstDate : firstDate // ignore: cast_nullable_to_non_nullable
as CalendarDate,recurrence: freezed == recurrence ? _self.recurrence : recurrence // ignore: cast_nullable_to_non_nullable
as RecurrenceRule?,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of RoomRoutine
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
