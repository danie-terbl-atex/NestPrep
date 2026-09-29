// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'routine_tick.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RoutineTick {

@JsonKey(includeToJson: false) String get id; String get routineId;@CalendarDateConverter() CalendarDate get occurrenceDate;/// The routine's helper on the day — what `own` reads it by.
 String get helperId; List<String> get doneItemIds;/// The member who last changed it — the helper, or family on her behalf.
 String get updatedBy;@ServerTimestampConverter() DateTime? get updatedAt;
/// Create a copy of RoutineTick
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RoutineTickCopyWith<RoutineTick> get copyWith => _$RoutineTickCopyWithImpl<RoutineTick>(this as RoutineTick, _$identity);

  /// Serializes this RoutineTick to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as RoutineTick;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RoutineTick&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.routineId, _this.routineId) || other.routineId == _this.routineId)&&(identical(other.occurrenceDate, _this.occurrenceDate) || other.occurrenceDate == _this.occurrenceDate)&&(identical(other.helperId, _this.helperId) || other.helperId == _this.helperId)&&const DeepCollectionEquality().equals(other.doneItemIds, _this.doneItemIds)&&(identical(other.updatedBy, _this.updatedBy) || other.updatedBy == _this.updatedBy)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as RoutineTick;
  return Object.hash(runtimeType,_this.id,_this.routineId,_this.occurrenceDate,_this.helperId,const DeepCollectionEquality().hash(_this.doneItemIds),_this.updatedBy,_this.updatedAt);
}

@override
String toString() {
  final _this = this as RoutineTick;
  return 'RoutineTick(id: ${_this.id}, routineId: ${_this.routineId}, occurrenceDate: ${_this.occurrenceDate}, helperId: ${_this.helperId}, doneItemIds: ${_this.doneItemIds}, updatedBy: ${_this.updatedBy}, updatedAt: ${_this.updatedAt})';
}


}

/// @nodoc
abstract mixin class $RoutineTickCopyWith<$Res>  {
  factory $RoutineTickCopyWith(RoutineTick value, $Res Function(RoutineTick) _then) = _$RoutineTickCopyWithImpl;
@useResult
$Res call({
@JsonKey(includeToJson: false) String id, String routineId,@CalendarDateConverter() CalendarDate occurrenceDate, String helperId, List<String> doneItemIds, String updatedBy,@ServerTimestampConverter() DateTime? updatedAt
});




}
/// @nodoc
class _$RoutineTickCopyWithImpl<$Res>
    implements $RoutineTickCopyWith<$Res> {
  _$RoutineTickCopyWithImpl(this._self, this._then);

  final RoutineTick _self;
  final $Res Function(RoutineTick) _then;

/// Create a copy of RoutineTick
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? routineId = null,Object? occurrenceDate = null,Object? helperId = null,Object? doneItemIds = null,Object? updatedBy = null,Object? updatedAt = freezed,}) {
  return _then(RoutineTick(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,routineId: null == routineId ? _self.routineId : routineId // ignore: cast_nullable_to_non_nullable
as String,occurrenceDate: null == occurrenceDate ? _self.occurrenceDate : occurrenceDate // ignore: cast_nullable_to_non_nullable
as CalendarDate,helperId: null == helperId ? _self.helperId : helperId // ignore: cast_nullable_to_non_nullable
as String,doneItemIds: null == doneItemIds ? _self.doneItemIds : doneItemIds // ignore: cast_nullable_to_non_nullable
as List<String>,updatedBy: null == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [RoutineTick].
extension RoutineTickPatterns on RoutineTick {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RoutineTick value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RoutineTick() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RoutineTick value)  $default,){
final _that = this;
switch (_that) {
case _RoutineTick():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RoutineTick value)?  $default,){
final _that = this;
switch (_that) {
case _RoutineTick() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  String routineId, @CalendarDateConverter()  CalendarDate occurrenceDate,  String helperId,  List<String> doneItemIds,  String updatedBy, @ServerTimestampConverter()  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RoutineTick() when $default != null:
return $default(_that.id,_that.routineId,_that.occurrenceDate,_that.helperId,_that.doneItemIds,_that.updatedBy,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  String routineId, @CalendarDateConverter()  CalendarDate occurrenceDate,  String helperId,  List<String> doneItemIds,  String updatedBy, @ServerTimestampConverter()  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _RoutineTick():
return $default(_that.id,_that.routineId,_that.occurrenceDate,_that.helperId,_that.doneItemIds,_that.updatedBy,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(includeToJson: false)  String id,  String routineId, @CalendarDateConverter()  CalendarDate occurrenceDate,  String helperId,  List<String> doneItemIds,  String updatedBy, @ServerTimestampConverter()  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _RoutineTick() when $default != null:
return $default(_that.id,_that.routineId,_that.occurrenceDate,_that.helperId,_that.doneItemIds,_that.updatedBy,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RoutineTick implements RoutineTick {
  const _RoutineTick({@JsonKey(includeToJson: false) required this.id, required this.routineId, @CalendarDateConverter() required this.occurrenceDate, required this.helperId,  List<String> doneItemIds = const <String>[], required this.updatedBy, @ServerTimestampConverter() this.updatedAt}): _doneItemIds = doneItemIds;
  factory _RoutineTick.fromJson(Map<String, dynamic> json) => _$RoutineTickFromJson(json);

@override@JsonKey(includeToJson: false) final  String id;
@override final  String routineId;
@override@CalendarDateConverter() final  CalendarDate occurrenceDate;
/// The routine's helper on the day — what `own` reads it by.
@override final  String helperId;
 final  List<String> _doneItemIds;
@override@JsonKey() List<String> get doneItemIds {
  if (_doneItemIds is EqualUnmodifiableListView) return _doneItemIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_doneItemIds);
}

/// The member who last changed it — the helper, or family on her behalf.
@override final  String updatedBy;
@override@ServerTimestampConverter() final  DateTime? updatedAt;

/// Create a copy of RoutineTick
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RoutineTickCopyWith<_RoutineTick> get copyWith => __$RoutineTickCopyWithImpl<_RoutineTick>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RoutineTickToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RoutineTick&&(identical(other.id, id) || other.id == id)&&(identical(other.routineId, routineId) || other.routineId == routineId)&&(identical(other.occurrenceDate, occurrenceDate) || other.occurrenceDate == occurrenceDate)&&(identical(other.helperId, helperId) || other.helperId == helperId)&&const DeepCollectionEquality().equals(other.doneItemIds, _doneItemIds)&&(identical(other.updatedBy, updatedBy) || other.updatedBy == updatedBy)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,routineId,occurrenceDate,helperId,const DeepCollectionEquality().hash(_doneItemIds),updatedBy,updatedAt);
}

@override
String toString() {
    return 'RoutineTick(id: $id, routineId: $routineId, occurrenceDate: $occurrenceDate, helperId: $helperId, doneItemIds: $doneItemIds, updatedBy: $updatedBy, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$RoutineTickCopyWith<$Res> implements $RoutineTickCopyWith<$Res> {
  factory _$RoutineTickCopyWith(_RoutineTick value, $Res Function(_RoutineTick) _then) = __$RoutineTickCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(includeToJson: false) String id, String routineId,@CalendarDateConverter() CalendarDate occurrenceDate, String helperId, List<String> doneItemIds, String updatedBy,@ServerTimestampConverter() DateTime? updatedAt
});




}
/// @nodoc
class __$RoutineTickCopyWithImpl<$Res>
    implements _$RoutineTickCopyWith<$Res> {
  __$RoutineTickCopyWithImpl(this._self, this._then);

  final _RoutineTick _self;
  final $Res Function(_RoutineTick) _then;

/// Create a copy of RoutineTick
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? routineId = null,Object? occurrenceDate = null,Object? helperId = null,Object? doneItemIds = null,Object? updatedBy = null,Object? updatedAt = freezed,}) {
  return _then(_RoutineTick(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,routineId: null == routineId ? _self.routineId : routineId // ignore: cast_nullable_to_non_nullable
as String,occurrenceDate: null == occurrenceDate ? _self.occurrenceDate : occurrenceDate // ignore: cast_nullable_to_non_nullable
as CalendarDate,helperId: null == helperId ? _self.helperId : helperId // ignore: cast_nullable_to_non_nullable
as String,doneItemIds: null == doneItemIds ? _self._doneItemIds : doneItemIds // ignore: cast_nullable_to_non_nullable
as List<String>,updatedBy: null == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
