// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'task_completion.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TaskCompletion {

@JsonKey(includeToJson: false) String get id; String get taskId;@CalendarDateConverter() CalendarDate get occurrenceDate;/// The member who actually did it — the actor.
 String get completedBy;/// The member it was for. Different from `completedBy` when an admin
/// completes on behalf of a profile nobody has claimed (household ADR-0001).
 String get completedFor;@ServerTimestampConverter() DateTime? get completedAt;
/// Create a copy of TaskCompletion
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TaskCompletionCopyWith<TaskCompletion> get copyWith => _$TaskCompletionCopyWithImpl<TaskCompletion>(this as TaskCompletion, _$identity);

  /// Serializes this TaskCompletion to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as TaskCompletion;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TaskCompletion&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.taskId, _this.taskId) || other.taskId == _this.taskId)&&(identical(other.occurrenceDate, _this.occurrenceDate) || other.occurrenceDate == _this.occurrenceDate)&&(identical(other.completedBy, _this.completedBy) || other.completedBy == _this.completedBy)&&(identical(other.completedFor, _this.completedFor) || other.completedFor == _this.completedFor)&&(identical(other.completedAt, _this.completedAt) || other.completedAt == _this.completedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as TaskCompletion;
  return Object.hash(runtimeType,_this.id,_this.taskId,_this.occurrenceDate,_this.completedBy,_this.completedFor,_this.completedAt);
}

@override
String toString() {
  final _this = this as TaskCompletion;
  return 'TaskCompletion(id: ${_this.id}, taskId: ${_this.taskId}, occurrenceDate: ${_this.occurrenceDate}, completedBy: ${_this.completedBy}, completedFor: ${_this.completedFor}, completedAt: ${_this.completedAt})';
}


}

/// @nodoc
abstract mixin class $TaskCompletionCopyWith<$Res>  {
  factory $TaskCompletionCopyWith(TaskCompletion value, $Res Function(TaskCompletion) _then) = _$TaskCompletionCopyWithImpl;
@useResult
$Res call({
@JsonKey(includeToJson: false) String id, String taskId,@CalendarDateConverter() CalendarDate occurrenceDate, String completedBy, String completedFor,@ServerTimestampConverter() DateTime? completedAt
});




}
/// @nodoc
class _$TaskCompletionCopyWithImpl<$Res>
    implements $TaskCompletionCopyWith<$Res> {
  _$TaskCompletionCopyWithImpl(this._self, this._then);

  final TaskCompletion _self;
  final $Res Function(TaskCompletion) _then;

/// Create a copy of TaskCompletion
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? taskId = null,Object? occurrenceDate = null,Object? completedBy = null,Object? completedFor = null,Object? completedAt = freezed,}) {
  return _then(TaskCompletion(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,taskId: null == taskId ? _self.taskId : taskId // ignore: cast_nullable_to_non_nullable
as String,occurrenceDate: null == occurrenceDate ? _self.occurrenceDate : occurrenceDate // ignore: cast_nullable_to_non_nullable
as CalendarDate,completedBy: null == completedBy ? _self.completedBy : completedBy // ignore: cast_nullable_to_non_nullable
as String,completedFor: null == completedFor ? _self.completedFor : completedFor // ignore: cast_nullable_to_non_nullable
as String,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [TaskCompletion].
extension TaskCompletionPatterns on TaskCompletion {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TaskCompletion value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TaskCompletion() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TaskCompletion value)  $default,){
final _that = this;
switch (_that) {
case _TaskCompletion():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TaskCompletion value)?  $default,){
final _that = this;
switch (_that) {
case _TaskCompletion() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  String taskId, @CalendarDateConverter()  CalendarDate occurrenceDate,  String completedBy,  String completedFor, @ServerTimestampConverter()  DateTime? completedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TaskCompletion() when $default != null:
return $default(_that.id,_that.taskId,_that.occurrenceDate,_that.completedBy,_that.completedFor,_that.completedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  String taskId, @CalendarDateConverter()  CalendarDate occurrenceDate,  String completedBy,  String completedFor, @ServerTimestampConverter()  DateTime? completedAt)  $default,) {final _that = this;
switch (_that) {
case _TaskCompletion():
return $default(_that.id,_that.taskId,_that.occurrenceDate,_that.completedBy,_that.completedFor,_that.completedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(includeToJson: false)  String id,  String taskId, @CalendarDateConverter()  CalendarDate occurrenceDate,  String completedBy,  String completedFor, @ServerTimestampConverter()  DateTime? completedAt)?  $default,) {final _that = this;
switch (_that) {
case _TaskCompletion() when $default != null:
return $default(_that.id,_that.taskId,_that.occurrenceDate,_that.completedBy,_that.completedFor,_that.completedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TaskCompletion extends TaskCompletion {
  const _TaskCompletion({@JsonKey(includeToJson: false) required this.id, required this.taskId, @CalendarDateConverter() required this.occurrenceDate, required this.completedBy, required this.completedFor, @ServerTimestampConverter() this.completedAt}): super._();
  factory _TaskCompletion.fromJson(Map<String, dynamic> json) => _$TaskCompletionFromJson(json);

@override@JsonKey(includeToJson: false) final  String id;
@override final  String taskId;
@override@CalendarDateConverter() final  CalendarDate occurrenceDate;
/// The member who actually did it — the actor.
@override final  String completedBy;
/// The member it was for. Different from `completedBy` when an admin
/// completes on behalf of a profile nobody has claimed (household ADR-0001).
@override final  String completedFor;
@override@ServerTimestampConverter() final  DateTime? completedAt;

/// Create a copy of TaskCompletion
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TaskCompletionCopyWith<_TaskCompletion> get copyWith => __$TaskCompletionCopyWithImpl<_TaskCompletion>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TaskCompletionToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TaskCompletion&&(identical(other.id, id) || other.id == id)&&(identical(other.taskId, taskId) || other.taskId == taskId)&&(identical(other.occurrenceDate, occurrenceDate) || other.occurrenceDate == occurrenceDate)&&(identical(other.completedBy, completedBy) || other.completedBy == completedBy)&&(identical(other.completedFor, completedFor) || other.completedFor == completedFor)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,taskId,occurrenceDate,completedBy,completedFor,completedAt);
}

@override
String toString() {
    return 'TaskCompletion(id: $id, taskId: $taskId, occurrenceDate: $occurrenceDate, completedBy: $completedBy, completedFor: $completedFor, completedAt: $completedAt)';
}


}

/// @nodoc
abstract mixin class _$TaskCompletionCopyWith<$Res> implements $TaskCompletionCopyWith<$Res> {
  factory _$TaskCompletionCopyWith(_TaskCompletion value, $Res Function(_TaskCompletion) _then) = __$TaskCompletionCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(includeToJson: false) String id, String taskId,@CalendarDateConverter() CalendarDate occurrenceDate, String completedBy, String completedFor,@ServerTimestampConverter() DateTime? completedAt
});




}
/// @nodoc
class __$TaskCompletionCopyWithImpl<$Res>
    implements _$TaskCompletionCopyWith<$Res> {
  __$TaskCompletionCopyWithImpl(this._self, this._then);

  final _TaskCompletion _self;
  final $Res Function(_TaskCompletion) _then;

/// Create a copy of TaskCompletion
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? taskId = null,Object? occurrenceDate = null,Object? completedBy = null,Object? completedFor = null,Object? completedAt = freezed,}) {
  return _then(_TaskCompletion(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,taskId: null == taskId ? _self.taskId : taskId // ignore: cast_nullable_to_non_nullable
as String,occurrenceDate: null == occurrenceDate ? _self.occurrenceDate : occurrenceDate // ignore: cast_nullable_to_non_nullable
as CalendarDate,completedBy: null == completedBy ? _self.completedBy : completedBy // ignore: cast_nullable_to_non_nullable
as String,completedFor: null == completedFor ? _self.completedFor : completedFor // ignore: cast_nullable_to_non_nullable
as String,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
