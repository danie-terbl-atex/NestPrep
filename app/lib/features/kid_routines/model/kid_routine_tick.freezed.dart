// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'kid_routine_tick.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$KidRoutineTick {

 String get routineId; String get kidId;@CalendarDateConverter() CalendarDate get occurrenceDate; List<String> get doneStepIds; String get updatedBy;@ServerTimestampConverter() DateTime? get updatedAt;
/// Create a copy of KidRoutineTick
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$KidRoutineTickCopyWith<KidRoutineTick> get copyWith => _$KidRoutineTickCopyWithImpl<KidRoutineTick>(this as KidRoutineTick, _$identity);

  /// Serializes this KidRoutineTick to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as KidRoutineTick;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is KidRoutineTick&&(identical(other.routineId, _this.routineId) || other.routineId == _this.routineId)&&(identical(other.kidId, _this.kidId) || other.kidId == _this.kidId)&&(identical(other.occurrenceDate, _this.occurrenceDate) || other.occurrenceDate == _this.occurrenceDate)&&const DeepCollectionEquality().equals(other.doneStepIds, _this.doneStepIds)&&(identical(other.updatedBy, _this.updatedBy) || other.updatedBy == _this.updatedBy)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as KidRoutineTick;
  return Object.hash(runtimeType,_this.routineId,_this.kidId,_this.occurrenceDate,const DeepCollectionEquality().hash(_this.doneStepIds),_this.updatedBy,_this.updatedAt);
}

@override
String toString() {
  final _this = this as KidRoutineTick;
  return 'KidRoutineTick(routineId: ${_this.routineId}, kidId: ${_this.kidId}, occurrenceDate: ${_this.occurrenceDate}, doneStepIds: ${_this.doneStepIds}, updatedBy: ${_this.updatedBy}, updatedAt: ${_this.updatedAt})';
}


}

/// @nodoc
abstract mixin class $KidRoutineTickCopyWith<$Res>  {
  factory $KidRoutineTickCopyWith(KidRoutineTick value, $Res Function(KidRoutineTick) _then) = _$KidRoutineTickCopyWithImpl;
@useResult
$Res call({
 String routineId, String kidId,@CalendarDateConverter() CalendarDate occurrenceDate, List<String> doneStepIds, String updatedBy,@ServerTimestampConverter() DateTime? updatedAt
});




}
/// @nodoc
class _$KidRoutineTickCopyWithImpl<$Res>
    implements $KidRoutineTickCopyWith<$Res> {
  _$KidRoutineTickCopyWithImpl(this._self, this._then);

  final KidRoutineTick _self;
  final $Res Function(KidRoutineTick) _then;

/// Create a copy of KidRoutineTick
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? routineId = null,Object? kidId = null,Object? occurrenceDate = null,Object? doneStepIds = null,Object? updatedBy = null,Object? updatedAt = freezed,}) {
  return _then(KidRoutineTick(
routineId: null == routineId ? _self.routineId : routineId // ignore: cast_nullable_to_non_nullable
as String,kidId: null == kidId ? _self.kidId : kidId // ignore: cast_nullable_to_non_nullable
as String,occurrenceDate: null == occurrenceDate ? _self.occurrenceDate : occurrenceDate // ignore: cast_nullable_to_non_nullable
as CalendarDate,doneStepIds: null == doneStepIds ? _self.doneStepIds : doneStepIds // ignore: cast_nullable_to_non_nullable
as List<String>,updatedBy: null == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [KidRoutineTick].
extension KidRoutineTickPatterns on KidRoutineTick {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _KidRoutineTick value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _KidRoutineTick() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _KidRoutineTick value)  $default,){
final _that = this;
switch (_that) {
case _KidRoutineTick():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _KidRoutineTick value)?  $default,){
final _that = this;
switch (_that) {
case _KidRoutineTick() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String routineId,  String kidId, @CalendarDateConverter()  CalendarDate occurrenceDate,  List<String> doneStepIds,  String updatedBy, @ServerTimestampConverter()  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _KidRoutineTick() when $default != null:
return $default(_that.routineId,_that.kidId,_that.occurrenceDate,_that.doneStepIds,_that.updatedBy,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String routineId,  String kidId, @CalendarDateConverter()  CalendarDate occurrenceDate,  List<String> doneStepIds,  String updatedBy, @ServerTimestampConverter()  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _KidRoutineTick():
return $default(_that.routineId,_that.kidId,_that.occurrenceDate,_that.doneStepIds,_that.updatedBy,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String routineId,  String kidId, @CalendarDateConverter()  CalendarDate occurrenceDate,  List<String> doneStepIds,  String updatedBy, @ServerTimestampConverter()  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _KidRoutineTick() when $default != null:
return $default(_that.routineId,_that.kidId,_that.occurrenceDate,_that.doneStepIds,_that.updatedBy,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _KidRoutineTick extends KidRoutineTick {
  const _KidRoutineTick({required this.routineId, required this.kidId, @CalendarDateConverter() required this.occurrenceDate,  List<String> doneStepIds = const <String>[], required this.updatedBy, @ServerTimestampConverter() this.updatedAt}): _doneStepIds = doneStepIds,super._();
  factory _KidRoutineTick.fromJson(Map<String, dynamic> json) => _$KidRoutineTickFromJson(json);

@override final  String routineId;
@override final  String kidId;
@override@CalendarDateConverter() final  CalendarDate occurrenceDate;
 final  List<String> _doneStepIds;
@override@JsonKey() List<String> get doneStepIds {
  if (_doneStepIds is EqualUnmodifiableListView) return _doneStepIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_doneStepIds);
}

@override final  String updatedBy;
@override@ServerTimestampConverter() final  DateTime? updatedAt;

/// Create a copy of KidRoutineTick
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$KidRoutineTickCopyWith<_KidRoutineTick> get copyWith => __$KidRoutineTickCopyWithImpl<_KidRoutineTick>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$KidRoutineTickToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _KidRoutineTick&&(identical(other.routineId, routineId) || other.routineId == routineId)&&(identical(other.kidId, kidId) || other.kidId == kidId)&&(identical(other.occurrenceDate, occurrenceDate) || other.occurrenceDate == occurrenceDate)&&const DeepCollectionEquality().equals(other.doneStepIds, _doneStepIds)&&(identical(other.updatedBy, updatedBy) || other.updatedBy == updatedBy)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,routineId,kidId,occurrenceDate,const DeepCollectionEquality().hash(_doneStepIds),updatedBy,updatedAt);
}

@override
String toString() {
    return 'KidRoutineTick(routineId: $routineId, kidId: $kidId, occurrenceDate: $occurrenceDate, doneStepIds: $doneStepIds, updatedBy: $updatedBy, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$KidRoutineTickCopyWith<$Res> implements $KidRoutineTickCopyWith<$Res> {
  factory _$KidRoutineTickCopyWith(_KidRoutineTick value, $Res Function(_KidRoutineTick) _then) = __$KidRoutineTickCopyWithImpl;
@override @useResult
$Res call({
 String routineId, String kidId,@CalendarDateConverter() CalendarDate occurrenceDate, List<String> doneStepIds, String updatedBy,@ServerTimestampConverter() DateTime? updatedAt
});




}
/// @nodoc
class __$KidRoutineTickCopyWithImpl<$Res>
    implements _$KidRoutineTickCopyWith<$Res> {
  __$KidRoutineTickCopyWithImpl(this._self, this._then);

  final _KidRoutineTick _self;
  final $Res Function(_KidRoutineTick) _then;

/// Create a copy of KidRoutineTick
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? routineId = null,Object? kidId = null,Object? occurrenceDate = null,Object? doneStepIds = null,Object? updatedBy = null,Object? updatedAt = freezed,}) {
  return _then(_KidRoutineTick(
routineId: null == routineId ? _self.routineId : routineId // ignore: cast_nullable_to_non_nullable
as String,kidId: null == kidId ? _self.kidId : kidId // ignore: cast_nullable_to_non_nullable
as String,occurrenceDate: null == occurrenceDate ? _self.occurrenceDate : occurrenceDate // ignore: cast_nullable_to_non_nullable
as CalendarDate,doneStepIds: null == doneStepIds ? _self._doneStepIds : doneStepIds // ignore: cast_nullable_to_non_nullable
as List<String>,updatedBy: null == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
