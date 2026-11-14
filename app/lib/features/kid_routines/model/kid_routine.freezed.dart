// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'kid_routine.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$KidRoutine {

@JsonKey(includeToJson: false) String get id; String get name;@JsonKey(unknownEnumValue: KidRoutineSlot.morning) KidRoutineSlot get slot; List<String> get kidIds;@CalendarDateConverter() CalendarDate get firstDate; RecurrenceRule? get recurrence;/// Minutes since midnight on the household's clock, or null for no time.
 int? get finishBy;/// Stars for finishing the whole routine.
 int get points; List<KidRoutineStep> get steps; String get createdBy;@ServerTimestampConverter() DateTime? get createdAt;
/// Create a copy of KidRoutine
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$KidRoutineCopyWith<KidRoutine> get copyWith => _$KidRoutineCopyWithImpl<KidRoutine>(this as KidRoutine, _$identity);

  /// Serializes this KidRoutine to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as KidRoutine;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is KidRoutine&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.slot, _this.slot) || other.slot == _this.slot)&&const DeepCollectionEquality().equals(other.kidIds, _this.kidIds)&&(identical(other.firstDate, _this.firstDate) || other.firstDate == _this.firstDate)&&(identical(other.recurrence, _this.recurrence) || other.recurrence == _this.recurrence)&&(identical(other.finishBy, _this.finishBy) || other.finishBy == _this.finishBy)&&(identical(other.points, _this.points) || other.points == _this.points)&&const DeepCollectionEquality().equals(other.steps, _this.steps)&&(identical(other.createdBy, _this.createdBy) || other.createdBy == _this.createdBy)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as KidRoutine;
  return Object.hash(runtimeType,_this.id,_this.name,_this.slot,const DeepCollectionEquality().hash(_this.kidIds),_this.firstDate,_this.recurrence,_this.finishBy,_this.points,const DeepCollectionEquality().hash(_this.steps),_this.createdBy,_this.createdAt);
}

@override
String toString() {
  final _this = this as KidRoutine;
  return 'KidRoutine(id: ${_this.id}, name: ${_this.name}, slot: ${_this.slot}, kidIds: ${_this.kidIds}, firstDate: ${_this.firstDate}, recurrence: ${_this.recurrence}, finishBy: ${_this.finishBy}, points: ${_this.points}, steps: ${_this.steps}, createdBy: ${_this.createdBy}, createdAt: ${_this.createdAt})';
}


}

/// @nodoc
abstract mixin class $KidRoutineCopyWith<$Res>  {
  factory $KidRoutineCopyWith(KidRoutine value, $Res Function(KidRoutine) _then) = _$KidRoutineCopyWithImpl;
@useResult
$Res call({
@JsonKey(includeToJson: false) String id, String name,@JsonKey(unknownEnumValue: KidRoutineSlot.morning) KidRoutineSlot slot, List<String> kidIds,@CalendarDateConverter() CalendarDate firstDate, RecurrenceRule? recurrence, int? finishBy, int points, List<KidRoutineStep> steps, String createdBy,@ServerTimestampConverter() DateTime? createdAt
});


$RecurrenceRuleCopyWith<$Res>? get recurrence;

}
/// @nodoc
class _$KidRoutineCopyWithImpl<$Res>
    implements $KidRoutineCopyWith<$Res> {
  _$KidRoutineCopyWithImpl(this._self, this._then);

  final KidRoutine _self;
  final $Res Function(KidRoutine) _then;

/// Create a copy of KidRoutine
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? slot = null,Object? kidIds = null,Object? firstDate = null,Object? recurrence = freezed,Object? finishBy = freezed,Object? points = null,Object? steps = null,Object? createdBy = null,Object? createdAt = freezed,}) {
  return _then(KidRoutine(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,slot: null == slot ? _self.slot : slot // ignore: cast_nullable_to_non_nullable
as KidRoutineSlot,kidIds: null == kidIds ? _self.kidIds : kidIds // ignore: cast_nullable_to_non_nullable
as List<String>,firstDate: null == firstDate ? _self.firstDate : firstDate // ignore: cast_nullable_to_non_nullable
as CalendarDate,recurrence: freezed == recurrence ? _self.recurrence : recurrence // ignore: cast_nullable_to_non_nullable
as RecurrenceRule?,finishBy: freezed == finishBy ? _self.finishBy : finishBy // ignore: cast_nullable_to_non_nullable
as int?,points: null == points ? _self.points : points // ignore: cast_nullable_to_non_nullable
as int,steps: null == steps ? _self.steps : steps // ignore: cast_nullable_to_non_nullable
as List<KidRoutineStep>,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of KidRoutine
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


/// Adds pattern-matching-related methods to [KidRoutine].
extension KidRoutinePatterns on KidRoutine {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _KidRoutine value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _KidRoutine() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _KidRoutine value)  $default,){
final _that = this;
switch (_that) {
case _KidRoutine():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _KidRoutine value)?  $default,){
final _that = this;
switch (_that) {
case _KidRoutine() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  String name, @JsonKey(unknownEnumValue: KidRoutineSlot.morning)  KidRoutineSlot slot,  List<String> kidIds, @CalendarDateConverter()  CalendarDate firstDate,  RecurrenceRule? recurrence,  int? finishBy,  int points,  List<KidRoutineStep> steps,  String createdBy, @ServerTimestampConverter()  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _KidRoutine() when $default != null:
return $default(_that.id,_that.name,_that.slot,_that.kidIds,_that.firstDate,_that.recurrence,_that.finishBy,_that.points,_that.steps,_that.createdBy,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  String name, @JsonKey(unknownEnumValue: KidRoutineSlot.morning)  KidRoutineSlot slot,  List<String> kidIds, @CalendarDateConverter()  CalendarDate firstDate,  RecurrenceRule? recurrence,  int? finishBy,  int points,  List<KidRoutineStep> steps,  String createdBy, @ServerTimestampConverter()  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _KidRoutine():
return $default(_that.id,_that.name,_that.slot,_that.kidIds,_that.firstDate,_that.recurrence,_that.finishBy,_that.points,_that.steps,_that.createdBy,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(includeToJson: false)  String id,  String name, @JsonKey(unknownEnumValue: KidRoutineSlot.morning)  KidRoutineSlot slot,  List<String> kidIds, @CalendarDateConverter()  CalendarDate firstDate,  RecurrenceRule? recurrence,  int? finishBy,  int points,  List<KidRoutineStep> steps,  String createdBy, @ServerTimestampConverter()  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _KidRoutine() when $default != null:
return $default(_that.id,_that.name,_that.slot,_that.kidIds,_that.firstDate,_that.recurrence,_that.finishBy,_that.points,_that.steps,_that.createdBy,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _KidRoutine implements KidRoutine {
  const _KidRoutine({@JsonKey(includeToJson: false) required this.id, required this.name, @JsonKey(unknownEnumValue: KidRoutineSlot.morning) required this.slot,  List<String> kidIds = const <String>[], @CalendarDateConverter() required this.firstDate, this.recurrence, this.finishBy, this.points = 0,  List<KidRoutineStep> steps = const <KidRoutineStep>[], required this.createdBy, @ServerTimestampConverter() this.createdAt}): _kidIds = kidIds,_steps = steps;
  factory _KidRoutine.fromJson(Map<String, dynamic> json) => _$KidRoutineFromJson(json);

@override@JsonKey(includeToJson: false) final  String id;
@override final  String name;
@override@JsonKey(unknownEnumValue: KidRoutineSlot.morning) final  KidRoutineSlot slot;
 final  List<String> _kidIds;
@override@JsonKey() List<String> get kidIds {
  if (_kidIds is EqualUnmodifiableListView) return _kidIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_kidIds);
}

@override@CalendarDateConverter() final  CalendarDate firstDate;
@override final  RecurrenceRule? recurrence;
/// Minutes since midnight on the household's clock, or null for no time.
@override final  int? finishBy;
/// Stars for finishing the whole routine.
@override@JsonKey() final  int points;
 final  List<KidRoutineStep> _steps;
@override@JsonKey() List<KidRoutineStep> get steps {
  if (_steps is EqualUnmodifiableListView) return _steps;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_steps);
}

@override final  String createdBy;
@override@ServerTimestampConverter() final  DateTime? createdAt;

/// Create a copy of KidRoutine
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$KidRoutineCopyWith<_KidRoutine> get copyWith => __$KidRoutineCopyWithImpl<_KidRoutine>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$KidRoutineToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _KidRoutine&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.slot, slot) || other.slot == slot)&&const DeepCollectionEquality().equals(other.kidIds, _kidIds)&&(identical(other.firstDate, firstDate) || other.firstDate == firstDate)&&(identical(other.recurrence, recurrence) || other.recurrence == recurrence)&&(identical(other.finishBy, finishBy) || other.finishBy == finishBy)&&(identical(other.points, points) || other.points == points)&&const DeepCollectionEquality().equals(other.steps, _steps)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,slot,const DeepCollectionEquality().hash(_kidIds),firstDate,recurrence,finishBy,points,const DeepCollectionEquality().hash(_steps),createdBy,createdAt);
}

@override
String toString() {
    return 'KidRoutine(id: $id, name: $name, slot: $slot, kidIds: $kidIds, firstDate: $firstDate, recurrence: $recurrence, finishBy: $finishBy, points: $points, steps: $steps, createdBy: $createdBy, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$KidRoutineCopyWith<$Res> implements $KidRoutineCopyWith<$Res> {
  factory _$KidRoutineCopyWith(_KidRoutine value, $Res Function(_KidRoutine) _then) = __$KidRoutineCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(includeToJson: false) String id, String name,@JsonKey(unknownEnumValue: KidRoutineSlot.morning) KidRoutineSlot slot, List<String> kidIds,@CalendarDateConverter() CalendarDate firstDate, RecurrenceRule? recurrence, int? finishBy, int points, List<KidRoutineStep> steps, String createdBy,@ServerTimestampConverter() DateTime? createdAt
});


@override $RecurrenceRuleCopyWith<$Res>? get recurrence;

}
/// @nodoc
class __$KidRoutineCopyWithImpl<$Res>
    implements _$KidRoutineCopyWith<$Res> {
  __$KidRoutineCopyWithImpl(this._self, this._then);

  final _KidRoutine _self;
  final $Res Function(_KidRoutine) _then;

/// Create a copy of KidRoutine
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? slot = null,Object? kidIds = null,Object? firstDate = null,Object? recurrence = freezed,Object? finishBy = freezed,Object? points = null,Object? steps = null,Object? createdBy = null,Object? createdAt = freezed,}) {
  return _then(_KidRoutine(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,slot: null == slot ? _self.slot : slot // ignore: cast_nullable_to_non_nullable
as KidRoutineSlot,kidIds: null == kidIds ? _self._kidIds : kidIds // ignore: cast_nullable_to_non_nullable
as List<String>,firstDate: null == firstDate ? _self.firstDate : firstDate // ignore: cast_nullable_to_non_nullable
as CalendarDate,recurrence: freezed == recurrence ? _self.recurrence : recurrence // ignore: cast_nullable_to_non_nullable
as RecurrenceRule?,finishBy: freezed == finishBy ? _self.finishBy : finishBy // ignore: cast_nullable_to_non_nullable
as int?,points: null == points ? _self.points : points // ignore: cast_nullable_to_non_nullable
as int,steps: null == steps ? _self._steps : steps // ignore: cast_nullable_to_non_nullable
as List<KidRoutineStep>,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of KidRoutine
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
