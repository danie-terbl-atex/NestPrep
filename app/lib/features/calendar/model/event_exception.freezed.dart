// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'event_exception.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$EventException {

@JsonKey(includeToJson: false) String get id; String get eventId;@CalendarDateConverter() CalendarDate get occurrenceDate; String get skippedBy;@ServerTimestampConverter() DateTime? get skippedAt;
/// Create a copy of EventException
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EventExceptionCopyWith<EventException> get copyWith => _$EventExceptionCopyWithImpl<EventException>(this as EventException, _$identity);

  /// Serializes this EventException to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as EventException;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EventException&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.eventId, _this.eventId) || other.eventId == _this.eventId)&&(identical(other.occurrenceDate, _this.occurrenceDate) || other.occurrenceDate == _this.occurrenceDate)&&(identical(other.skippedBy, _this.skippedBy) || other.skippedBy == _this.skippedBy)&&(identical(other.skippedAt, _this.skippedAt) || other.skippedAt == _this.skippedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as EventException;
  return Object.hash(runtimeType,_this.id,_this.eventId,_this.occurrenceDate,_this.skippedBy,_this.skippedAt);
}

@override
String toString() {
  final _this = this as EventException;
  return 'EventException(id: ${_this.id}, eventId: ${_this.eventId}, occurrenceDate: ${_this.occurrenceDate}, skippedBy: ${_this.skippedBy}, skippedAt: ${_this.skippedAt})';
}


}

/// @nodoc
abstract mixin class $EventExceptionCopyWith<$Res>  {
  factory $EventExceptionCopyWith(EventException value, $Res Function(EventException) _then) = _$EventExceptionCopyWithImpl;
@useResult
$Res call({
@JsonKey(includeToJson: false) String id, String eventId,@CalendarDateConverter() CalendarDate occurrenceDate, String skippedBy,@ServerTimestampConverter() DateTime? skippedAt
});




}
/// @nodoc
class _$EventExceptionCopyWithImpl<$Res>
    implements $EventExceptionCopyWith<$Res> {
  _$EventExceptionCopyWithImpl(this._self, this._then);

  final EventException _self;
  final $Res Function(EventException) _then;

/// Create a copy of EventException
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? eventId = null,Object? occurrenceDate = null,Object? skippedBy = null,Object? skippedAt = freezed,}) {
  return _then(EventException(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,eventId: null == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String,occurrenceDate: null == occurrenceDate ? _self.occurrenceDate : occurrenceDate // ignore: cast_nullable_to_non_nullable
as CalendarDate,skippedBy: null == skippedBy ? _self.skippedBy : skippedBy // ignore: cast_nullable_to_non_nullable
as String,skippedAt: freezed == skippedAt ? _self.skippedAt : skippedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [EventException].
extension EventExceptionPatterns on EventException {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EventException value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EventException() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EventException value)  $default,){
final _that = this;
switch (_that) {
case _EventException():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EventException value)?  $default,){
final _that = this;
switch (_that) {
case _EventException() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  String eventId, @CalendarDateConverter()  CalendarDate occurrenceDate,  String skippedBy, @ServerTimestampConverter()  DateTime? skippedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EventException() when $default != null:
return $default(_that.id,_that.eventId,_that.occurrenceDate,_that.skippedBy,_that.skippedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  String eventId, @CalendarDateConverter()  CalendarDate occurrenceDate,  String skippedBy, @ServerTimestampConverter()  DateTime? skippedAt)  $default,) {final _that = this;
switch (_that) {
case _EventException():
return $default(_that.id,_that.eventId,_that.occurrenceDate,_that.skippedBy,_that.skippedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(includeToJson: false)  String id,  String eventId, @CalendarDateConverter()  CalendarDate occurrenceDate,  String skippedBy, @ServerTimestampConverter()  DateTime? skippedAt)?  $default,) {final _that = this;
switch (_that) {
case _EventException() when $default != null:
return $default(_that.id,_that.eventId,_that.occurrenceDate,_that.skippedBy,_that.skippedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EventException extends EventException {
  const _EventException({@JsonKey(includeToJson: false) required this.id, required this.eventId, @CalendarDateConverter() required this.occurrenceDate, required this.skippedBy, @ServerTimestampConverter() this.skippedAt}): super._();
  factory _EventException.fromJson(Map<String, dynamic> json) => _$EventExceptionFromJson(json);

@override@JsonKey(includeToJson: false) final  String id;
@override final  String eventId;
@override@CalendarDateConverter() final  CalendarDate occurrenceDate;
@override final  String skippedBy;
@override@ServerTimestampConverter() final  DateTime? skippedAt;

/// Create a copy of EventException
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EventExceptionCopyWith<_EventException> get copyWith => __$EventExceptionCopyWithImpl<_EventException>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EventExceptionToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _EventException&&(identical(other.id, id) || other.id == id)&&(identical(other.eventId, eventId) || other.eventId == eventId)&&(identical(other.occurrenceDate, occurrenceDate) || other.occurrenceDate == occurrenceDate)&&(identical(other.skippedBy, skippedBy) || other.skippedBy == skippedBy)&&(identical(other.skippedAt, skippedAt) || other.skippedAt == skippedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,eventId,occurrenceDate,skippedBy,skippedAt);
}

@override
String toString() {
    return 'EventException(id: $id, eventId: $eventId, occurrenceDate: $occurrenceDate, skippedBy: $skippedBy, skippedAt: $skippedAt)';
}


}

/// @nodoc
abstract mixin class _$EventExceptionCopyWith<$Res> implements $EventExceptionCopyWith<$Res> {
  factory _$EventExceptionCopyWith(_EventException value, $Res Function(_EventException) _then) = __$EventExceptionCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(includeToJson: false) String id, String eventId,@CalendarDateConverter() CalendarDate occurrenceDate, String skippedBy,@ServerTimestampConverter() DateTime? skippedAt
});




}
/// @nodoc
class __$EventExceptionCopyWithImpl<$Res>
    implements _$EventExceptionCopyWith<$Res> {
  __$EventExceptionCopyWithImpl(this._self, this._then);

  final _EventException _self;
  final $Res Function(_EventException) _then;

/// Create a copy of EventException
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? eventId = null,Object? occurrenceDate = null,Object? skippedBy = null,Object? skippedAt = freezed,}) {
  return _then(_EventException(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,eventId: null == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String,occurrenceDate: null == occurrenceDate ? _self.occurrenceDate : occurrenceDate // ignore: cast_nullable_to_non_nullable
as CalendarDate,skippedBy: null == skippedBy ? _self.skippedBy : skippedBy // ignore: cast_nullable_to_non_nullable
as String,skippedAt: freezed == skippedAt ? _self.skippedAt : skippedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
