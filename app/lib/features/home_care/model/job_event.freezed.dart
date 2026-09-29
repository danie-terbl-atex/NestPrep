// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'job_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$JobEvent {

/// The revision the job moved to, as its document id.
@JsonKey(includeToJson: false) String get id;@JsonKey(unknownEnumValue: JobStatus.assigned) JobStatus get status;/// The member profile that made the change.
 String get by; String? get note;@ServerTimestampConverter() DateTime? get at;
/// Create a copy of JobEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JobEventCopyWith<JobEvent> get copyWith => _$JobEventCopyWithImpl<JobEvent>(this as JobEvent, _$identity);

  /// Serializes this JobEvent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as JobEvent;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JobEvent&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.by, _this.by) || other.by == _this.by)&&(identical(other.note, _this.note) || other.note == _this.note)&&(identical(other.at, _this.at) || other.at == _this.at));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as JobEvent;
  return Object.hash(runtimeType,_this.id,_this.status,_this.by,_this.note,_this.at);
}

@override
String toString() {
  final _this = this as JobEvent;
  return 'JobEvent(id: ${_this.id}, status: ${_this.status}, by: ${_this.by}, note: ${_this.note}, at: ${_this.at})';
}


}

/// @nodoc
abstract mixin class $JobEventCopyWith<$Res>  {
  factory $JobEventCopyWith(JobEvent value, $Res Function(JobEvent) _then) = _$JobEventCopyWithImpl;
@useResult
$Res call({
@JsonKey(includeToJson: false) String id,@JsonKey(unknownEnumValue: JobStatus.assigned) JobStatus status, String by, String? note,@ServerTimestampConverter() DateTime? at
});




}
/// @nodoc
class _$JobEventCopyWithImpl<$Res>
    implements $JobEventCopyWith<$Res> {
  _$JobEventCopyWithImpl(this._self, this._then);

  final JobEvent _self;
  final $Res Function(JobEvent) _then;

/// Create a copy of JobEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? status = null,Object? by = null,Object? note = freezed,Object? at = freezed,}) {
  return _then(JobEvent(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as JobStatus,by: null == by ? _self.by : by // ignore: cast_nullable_to_non_nullable
as String,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,at: freezed == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [JobEvent].
extension JobEventPatterns on JobEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _JobEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _JobEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _JobEvent value)  $default,){
final _that = this;
switch (_that) {
case _JobEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _JobEvent value)?  $default,){
final _that = this;
switch (_that) {
case _JobEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id, @JsonKey(unknownEnumValue: JobStatus.assigned)  JobStatus status,  String by,  String? note, @ServerTimestampConverter()  DateTime? at)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _JobEvent() when $default != null:
return $default(_that.id,_that.status,_that.by,_that.note,_that.at);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id, @JsonKey(unknownEnumValue: JobStatus.assigned)  JobStatus status,  String by,  String? note, @ServerTimestampConverter()  DateTime? at)  $default,) {final _that = this;
switch (_that) {
case _JobEvent():
return $default(_that.id,_that.status,_that.by,_that.note,_that.at);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(includeToJson: false)  String id, @JsonKey(unknownEnumValue: JobStatus.assigned)  JobStatus status,  String by,  String? note, @ServerTimestampConverter()  DateTime? at)?  $default,) {final _that = this;
switch (_that) {
case _JobEvent() when $default != null:
return $default(_that.id,_that.status,_that.by,_that.note,_that.at);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _JobEvent extends JobEvent {
  const _JobEvent({@JsonKey(includeToJson: false) required this.id, @JsonKey(unknownEnumValue: JobStatus.assigned) required this.status, required this.by, this.note, @ServerTimestampConverter() this.at}): super._();
  factory _JobEvent.fromJson(Map<String, dynamic> json) => _$JobEventFromJson(json);

/// The revision the job moved to, as its document id.
@override@JsonKey(includeToJson: false) final  String id;
@override@JsonKey(unknownEnumValue: JobStatus.assigned) final  JobStatus status;
/// The member profile that made the change.
@override final  String by;
@override final  String? note;
@override@ServerTimestampConverter() final  DateTime? at;

/// Create a copy of JobEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JobEventCopyWith<_JobEvent> get copyWith => __$JobEventCopyWithImpl<_JobEvent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$JobEventToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _JobEvent&&(identical(other.id, id) || other.id == id)&&(identical(other.status, status) || other.status == status)&&(identical(other.by, by) || other.by == by)&&(identical(other.note, note) || other.note == note)&&(identical(other.at, at) || other.at == at));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,status,by,note,at);
}

@override
String toString() {
    return 'JobEvent(id: $id, status: $status, by: $by, note: $note, at: $at)';
}


}

/// @nodoc
abstract mixin class _$JobEventCopyWith<$Res> implements $JobEventCopyWith<$Res> {
  factory _$JobEventCopyWith(_JobEvent value, $Res Function(_JobEvent) _then) = __$JobEventCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(includeToJson: false) String id,@JsonKey(unknownEnumValue: JobStatus.assigned) JobStatus status, String by, String? note,@ServerTimestampConverter() DateTime? at
});




}
/// @nodoc
class __$JobEventCopyWithImpl<$Res>
    implements _$JobEventCopyWith<$Res> {
  __$JobEventCopyWithImpl(this._self, this._then);

  final _JobEvent _self;
  final $Res Function(_JobEvent) _then;

/// Create a copy of JobEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? status = null,Object? by = null,Object? note = freezed,Object? at = freezed,}) {
  return _then(_JobEvent(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as JobStatus,by: null == by ? _self.by : by // ignore: cast_nullable_to_non_nullable
as String,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,at: freezed == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
