// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'task.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Task {

@JsonKey(includeToJson: false) String get id; String get title; String? get note;@CalendarDateConverter() CalendarDate get dueDate; RecurrenceRule? get recurrence;/// The member profiles this is for. **Empty means anyone**, which is what
/// "somebody take the bins out" actually means.
 List<String> get assigneeIds;/// The member profile that created it — not the account.
 String get createdBy;/// The routine this belongs to, whose schedule it then follows.
 String? get routineId;@ServerTimestampConverter() DateTime? get createdAt;/// The stars a child earns for doing it — 0 for none (todos ADR-0003).
/// Only family sets it, and a starred chore always names its children.
 int get points;/// Whether a parent checks it before the stars land (todos ADR-0003).
 bool get needsApproval;
/// Create a copy of Task
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TaskCopyWith<Task> get copyWith => _$TaskCopyWithImpl<Task>(this as Task, _$identity);

  /// Serializes this Task to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Task;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Task&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.note, _this.note) || other.note == _this.note)&&(identical(other.dueDate, _this.dueDate) || other.dueDate == _this.dueDate)&&(identical(other.recurrence, _this.recurrence) || other.recurrence == _this.recurrence)&&const DeepCollectionEquality().equals(other.assigneeIds, _this.assigneeIds)&&(identical(other.createdBy, _this.createdBy) || other.createdBy == _this.createdBy)&&(identical(other.routineId, _this.routineId) || other.routineId == _this.routineId)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.points, _this.points) || other.points == _this.points)&&(identical(other.needsApproval, _this.needsApproval) || other.needsApproval == _this.needsApproval));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Task;
  return Object.hash(runtimeType,_this.id,_this.title,_this.note,_this.dueDate,_this.recurrence,const DeepCollectionEquality().hash(_this.assigneeIds),_this.createdBy,_this.routineId,_this.createdAt,_this.points,_this.needsApproval);
}

@override
String toString() {
  final _this = this as Task;
  return 'Task(id: ${_this.id}, title: ${_this.title}, note: ${_this.note}, dueDate: ${_this.dueDate}, recurrence: ${_this.recurrence}, assigneeIds: ${_this.assigneeIds}, createdBy: ${_this.createdBy}, routineId: ${_this.routineId}, createdAt: ${_this.createdAt}, points: ${_this.points}, needsApproval: ${_this.needsApproval})';
}


}

/// @nodoc
abstract mixin class $TaskCopyWith<$Res>  {
  factory $TaskCopyWith(Task value, $Res Function(Task) _then) = _$TaskCopyWithImpl;
@useResult
$Res call({
@JsonKey(includeToJson: false) String id, String title, String? note,@CalendarDateConverter() CalendarDate dueDate, RecurrenceRule? recurrence, List<String> assigneeIds, String createdBy, String? routineId,@ServerTimestampConverter() DateTime? createdAt, int points, bool needsApproval
});


$RecurrenceRuleCopyWith<$Res>? get recurrence;

}
/// @nodoc
class _$TaskCopyWithImpl<$Res>
    implements $TaskCopyWith<$Res> {
  _$TaskCopyWithImpl(this._self, this._then);

  final Task _self;
  final $Res Function(Task) _then;

/// Create a copy of Task
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? note = freezed,Object? dueDate = null,Object? recurrence = freezed,Object? assigneeIds = null,Object? createdBy = null,Object? routineId = freezed,Object? createdAt = freezed,Object? points = null,Object? needsApproval = null,}) {
  return _then(Task(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,dueDate: null == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as CalendarDate,recurrence: freezed == recurrence ? _self.recurrence : recurrence // ignore: cast_nullable_to_non_nullable
as RecurrenceRule?,assigneeIds: null == assigneeIds ? _self.assigneeIds : assigneeIds // ignore: cast_nullable_to_non_nullable
as List<String>,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,routineId: freezed == routineId ? _self.routineId : routineId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,points: null == points ? _self.points : points // ignore: cast_nullable_to_non_nullable
as int,needsApproval: null == needsApproval ? _self.needsApproval : needsApproval // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of Task
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


/// Adds pattern-matching-related methods to [Task].
extension TaskPatterns on Task {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Task value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Task() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Task value)  $default,){
final _that = this;
switch (_that) {
case _Task():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Task value)?  $default,){
final _that = this;
switch (_that) {
case _Task() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  String title,  String? note, @CalendarDateConverter()  CalendarDate dueDate,  RecurrenceRule? recurrence,  List<String> assigneeIds,  String createdBy,  String? routineId, @ServerTimestampConverter()  DateTime? createdAt,  int points,  bool needsApproval)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Task() when $default != null:
return $default(_that.id,_that.title,_that.note,_that.dueDate,_that.recurrence,_that.assigneeIds,_that.createdBy,_that.routineId,_that.createdAt,_that.points,_that.needsApproval);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  String title,  String? note, @CalendarDateConverter()  CalendarDate dueDate,  RecurrenceRule? recurrence,  List<String> assigneeIds,  String createdBy,  String? routineId, @ServerTimestampConverter()  DateTime? createdAt,  int points,  bool needsApproval)  $default,) {final _that = this;
switch (_that) {
case _Task():
return $default(_that.id,_that.title,_that.note,_that.dueDate,_that.recurrence,_that.assigneeIds,_that.createdBy,_that.routineId,_that.createdAt,_that.points,_that.needsApproval);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(includeToJson: false)  String id,  String title,  String? note, @CalendarDateConverter()  CalendarDate dueDate,  RecurrenceRule? recurrence,  List<String> assigneeIds,  String createdBy,  String? routineId, @ServerTimestampConverter()  DateTime? createdAt,  int points,  bool needsApproval)?  $default,) {final _that = this;
switch (_that) {
case _Task() when $default != null:
return $default(_that.id,_that.title,_that.note,_that.dueDate,_that.recurrence,_that.assigneeIds,_that.createdBy,_that.routineId,_that.createdAt,_that.points,_that.needsApproval);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Task extends Task {
  const _Task({@JsonKey(includeToJson: false) required this.id, required this.title, this.note, @CalendarDateConverter() required this.dueDate, this.recurrence,  List<String> assigneeIds = const <String>[], required this.createdBy, this.routineId, @ServerTimestampConverter() this.createdAt, this.points = 0, this.needsApproval = false}): _assigneeIds = assigneeIds,super._();
  factory _Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);

@override@JsonKey(includeToJson: false) final  String id;
@override final  String title;
@override final  String? note;
@override@CalendarDateConverter() final  CalendarDate dueDate;
@override final  RecurrenceRule? recurrence;
/// The member profiles this is for. **Empty means anyone**, which is what
/// "somebody take the bins out" actually means.
 final  List<String> _assigneeIds;
/// The member profiles this is for. **Empty means anyone**, which is what
/// "somebody take the bins out" actually means.
@override@JsonKey() List<String> get assigneeIds {
  if (_assigneeIds is EqualUnmodifiableListView) return _assigneeIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_assigneeIds);
}

/// The member profile that created it — not the account.
@override final  String createdBy;
/// The routine this belongs to, whose schedule it then follows.
@override final  String? routineId;
@override@ServerTimestampConverter() final  DateTime? createdAt;
/// The stars a child earns for doing it — 0 for none (todos ADR-0003).
/// Only family sets it, and a starred chore always names its children.
@override@JsonKey() final  int points;
/// Whether a parent checks it before the stars land (todos ADR-0003).
@override@JsonKey() final  bool needsApproval;

/// Create a copy of Task
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TaskCopyWith<_Task> get copyWith => __$TaskCopyWithImpl<_Task>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TaskToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Task&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.note, note) || other.note == note)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&(identical(other.recurrence, recurrence) || other.recurrence == recurrence)&&const DeepCollectionEquality().equals(other.assigneeIds, _assigneeIds)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.routineId, routineId) || other.routineId == routineId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.points, points) || other.points == points)&&(identical(other.needsApproval, needsApproval) || other.needsApproval == needsApproval));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,title,note,dueDate,recurrence,const DeepCollectionEquality().hash(_assigneeIds),createdBy,routineId,createdAt,points,needsApproval);
}

@override
String toString() {
    return 'Task(id: $id, title: $title, note: $note, dueDate: $dueDate, recurrence: $recurrence, assigneeIds: $assigneeIds, createdBy: $createdBy, routineId: $routineId, createdAt: $createdAt, points: $points, needsApproval: $needsApproval)';
}


}

/// @nodoc
abstract mixin class _$TaskCopyWith<$Res> implements $TaskCopyWith<$Res> {
  factory _$TaskCopyWith(_Task value, $Res Function(_Task) _then) = __$TaskCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(includeToJson: false) String id, String title, String? note,@CalendarDateConverter() CalendarDate dueDate, RecurrenceRule? recurrence, List<String> assigneeIds, String createdBy, String? routineId,@ServerTimestampConverter() DateTime? createdAt, int points, bool needsApproval
});


@override $RecurrenceRuleCopyWith<$Res>? get recurrence;

}
/// @nodoc
class __$TaskCopyWithImpl<$Res>
    implements _$TaskCopyWith<$Res> {
  __$TaskCopyWithImpl(this._self, this._then);

  final _Task _self;
  final $Res Function(_Task) _then;

/// Create a copy of Task
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? note = freezed,Object? dueDate = null,Object? recurrence = freezed,Object? assigneeIds = null,Object? createdBy = null,Object? routineId = freezed,Object? createdAt = freezed,Object? points = null,Object? needsApproval = null,}) {
  return _then(_Task(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,dueDate: null == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as CalendarDate,recurrence: freezed == recurrence ? _self.recurrence : recurrence // ignore: cast_nullable_to_non_nullable
as RecurrenceRule?,assigneeIds: null == assigneeIds ? _self._assigneeIds : assigneeIds // ignore: cast_nullable_to_non_nullable
as List<String>,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,routineId: freezed == routineId ? _self.routineId : routineId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,points: null == points ? _self.points : points // ignore: cast_nullable_to_non_nullable
as int,needsApproval: null == needsApproval ? _self.needsApproval : needsApproval // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of Task
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
