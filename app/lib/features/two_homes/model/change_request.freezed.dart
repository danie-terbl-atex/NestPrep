// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'change_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ChangeRequest {

@JsonKey(includeToJson: false) String get id;@JsonKey(unknownEnumValue: ChangeKind.swap) ChangeKind get kind;/// A swap's first and last day, and the home that would have the child.
@NullableCalendarDateConverter() CalendarDate? get from;@NullableCalendarDateConverter() CalendarDate? get to;@JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) CustodySide? get toSide;/// A proposed schedule.
 CustodySchedule? get schedule; String? get note; CustodySide get proposedBySide;@JsonKey(unknownEnumValue: RequestStatus.closed) RequestStatus get status;@ServerTimestampConverter() DateTime? get createdAt;@NullableTimestampConverter() DateTime? get answeredAt;@JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) CustodySide? get answeredBySide; String? get answerNote;
/// Create a copy of ChangeRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChangeRequestCopyWith<ChangeRequest> get copyWith => _$ChangeRequestCopyWithImpl<ChangeRequest>(this as ChangeRequest, _$identity);

  /// Serializes this ChangeRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ChangeRequest;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChangeRequest&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.from, _this.from) || other.from == _this.from)&&(identical(other.to, _this.to) || other.to == _this.to)&&(identical(other.toSide, _this.toSide) || other.toSide == _this.toSide)&&(identical(other.schedule, _this.schedule) || other.schedule == _this.schedule)&&(identical(other.note, _this.note) || other.note == _this.note)&&(identical(other.proposedBySide, _this.proposedBySide) || other.proposedBySide == _this.proposedBySide)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.answeredAt, _this.answeredAt) || other.answeredAt == _this.answeredAt)&&(identical(other.answeredBySide, _this.answeredBySide) || other.answeredBySide == _this.answeredBySide)&&(identical(other.answerNote, _this.answerNote) || other.answerNote == _this.answerNote));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ChangeRequest;
  return Object.hash(runtimeType,_this.id,_this.kind,_this.from,_this.to,_this.toSide,_this.schedule,_this.note,_this.proposedBySide,_this.status,_this.createdAt,_this.answeredAt,_this.answeredBySide,_this.answerNote);
}

@override
String toString() {
  final _this = this as ChangeRequest;
  return 'ChangeRequest(id: ${_this.id}, kind: ${_this.kind}, from: ${_this.from}, to: ${_this.to}, toSide: ${_this.toSide}, schedule: ${_this.schedule}, note: ${_this.note}, proposedBySide: ${_this.proposedBySide}, status: ${_this.status}, createdAt: ${_this.createdAt}, answeredAt: ${_this.answeredAt}, answeredBySide: ${_this.answeredBySide}, answerNote: ${_this.answerNote})';
}


}

/// @nodoc
abstract mixin class $ChangeRequestCopyWith<$Res>  {
  factory $ChangeRequestCopyWith(ChangeRequest value, $Res Function(ChangeRequest) _then) = _$ChangeRequestCopyWithImpl;
@useResult
$Res call({
@JsonKey(includeToJson: false) String id,@JsonKey(unknownEnumValue: ChangeKind.swap) ChangeKind kind,@NullableCalendarDateConverter() CalendarDate? from,@NullableCalendarDateConverter() CalendarDate? to,@JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) CustodySide? toSide, CustodySchedule? schedule, String? note, CustodySide proposedBySide,@JsonKey(unknownEnumValue: RequestStatus.closed) RequestStatus status,@ServerTimestampConverter() DateTime? createdAt,@NullableTimestampConverter() DateTime? answeredAt,@JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) CustodySide? answeredBySide, String? answerNote
});


$CustodyScheduleCopyWith<$Res>? get schedule;

}
/// @nodoc
class _$ChangeRequestCopyWithImpl<$Res>
    implements $ChangeRequestCopyWith<$Res> {
  _$ChangeRequestCopyWithImpl(this._self, this._then);

  final ChangeRequest _self;
  final $Res Function(ChangeRequest) _then;

/// Create a copy of ChangeRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? kind = null,Object? from = freezed,Object? to = freezed,Object? toSide = freezed,Object? schedule = freezed,Object? note = freezed,Object? proposedBySide = null,Object? status = null,Object? createdAt = freezed,Object? answeredAt = freezed,Object? answeredBySide = freezed,Object? answerNote = freezed,}) {
  return _then(ChangeRequest(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as ChangeKind,from: freezed == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as CalendarDate?,to: freezed == to ? _self.to : to // ignore: cast_nullable_to_non_nullable
as CalendarDate?,toSide: freezed == toSide ? _self.toSide : toSide // ignore: cast_nullable_to_non_nullable
as CustodySide?,schedule: freezed == schedule ? _self.schedule : schedule // ignore: cast_nullable_to_non_nullable
as CustodySchedule?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,proposedBySide: null == proposedBySide ? _self.proposedBySide : proposedBySide // ignore: cast_nullable_to_non_nullable
as CustodySide,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as RequestStatus,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,answeredAt: freezed == answeredAt ? _self.answeredAt : answeredAt // ignore: cast_nullable_to_non_nullable
as DateTime?,answeredBySide: freezed == answeredBySide ? _self.answeredBySide : answeredBySide // ignore: cast_nullable_to_non_nullable
as CustodySide?,answerNote: freezed == answerNote ? _self.answerNote : answerNote // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of ChangeRequest
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CustodyScheduleCopyWith<$Res>? get schedule {
    if (_self.schedule == null) {
    return null;
  }

  return $CustodyScheduleCopyWith<$Res>(_self.schedule!, (value) {
    return _then(_self.copyWith(schedule: value));
  });
}
}


/// Adds pattern-matching-related methods to [ChangeRequest].
extension ChangeRequestPatterns on ChangeRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChangeRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChangeRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChangeRequest value)  $default,){
final _that = this;
switch (_that) {
case _ChangeRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChangeRequest value)?  $default,){
final _that = this;
switch (_that) {
case _ChangeRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id, @JsonKey(unknownEnumValue: ChangeKind.swap)  ChangeKind kind, @NullableCalendarDateConverter()  CalendarDate? from, @NullableCalendarDateConverter()  CalendarDate? to, @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)  CustodySide? toSide,  CustodySchedule? schedule,  String? note,  CustodySide proposedBySide, @JsonKey(unknownEnumValue: RequestStatus.closed)  RequestStatus status, @ServerTimestampConverter()  DateTime? createdAt, @NullableTimestampConverter()  DateTime? answeredAt, @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)  CustodySide? answeredBySide,  String? answerNote)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChangeRequest() when $default != null:
return $default(_that.id,_that.kind,_that.from,_that.to,_that.toSide,_that.schedule,_that.note,_that.proposedBySide,_that.status,_that.createdAt,_that.answeredAt,_that.answeredBySide,_that.answerNote);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id, @JsonKey(unknownEnumValue: ChangeKind.swap)  ChangeKind kind, @NullableCalendarDateConverter()  CalendarDate? from, @NullableCalendarDateConverter()  CalendarDate? to, @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)  CustodySide? toSide,  CustodySchedule? schedule,  String? note,  CustodySide proposedBySide, @JsonKey(unknownEnumValue: RequestStatus.closed)  RequestStatus status, @ServerTimestampConverter()  DateTime? createdAt, @NullableTimestampConverter()  DateTime? answeredAt, @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)  CustodySide? answeredBySide,  String? answerNote)  $default,) {final _that = this;
switch (_that) {
case _ChangeRequest():
return $default(_that.id,_that.kind,_that.from,_that.to,_that.toSide,_that.schedule,_that.note,_that.proposedBySide,_that.status,_that.createdAt,_that.answeredAt,_that.answeredBySide,_that.answerNote);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(includeToJson: false)  String id, @JsonKey(unknownEnumValue: ChangeKind.swap)  ChangeKind kind, @NullableCalendarDateConverter()  CalendarDate? from, @NullableCalendarDateConverter()  CalendarDate? to, @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)  CustodySide? toSide,  CustodySchedule? schedule,  String? note,  CustodySide proposedBySide, @JsonKey(unknownEnumValue: RequestStatus.closed)  RequestStatus status, @ServerTimestampConverter()  DateTime? createdAt, @NullableTimestampConverter()  DateTime? answeredAt, @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)  CustodySide? answeredBySide,  String? answerNote)?  $default,) {final _that = this;
switch (_that) {
case _ChangeRequest() when $default != null:
return $default(_that.id,_that.kind,_that.from,_that.to,_that.toSide,_that.schedule,_that.note,_that.proposedBySide,_that.status,_that.createdAt,_that.answeredAt,_that.answeredBySide,_that.answerNote);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChangeRequest extends ChangeRequest {
  const _ChangeRequest({@JsonKey(includeToJson: false) required this.id, @JsonKey(unknownEnumValue: ChangeKind.swap) required this.kind, @NullableCalendarDateConverter() this.from, @NullableCalendarDateConverter() this.to, @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) this.toSide, this.schedule, this.note, required this.proposedBySide, @JsonKey(unknownEnumValue: RequestStatus.closed) required this.status, @ServerTimestampConverter() this.createdAt, @NullableTimestampConverter() this.answeredAt, @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) this.answeredBySide, this.answerNote}): super._();
  factory _ChangeRequest.fromJson(Map<String, dynamic> json) => _$ChangeRequestFromJson(json);

@override@JsonKey(includeToJson: false) final  String id;
@override@JsonKey(unknownEnumValue: ChangeKind.swap) final  ChangeKind kind;
/// A swap's first and last day, and the home that would have the child.
@override@NullableCalendarDateConverter() final  CalendarDate? from;
@override@NullableCalendarDateConverter() final  CalendarDate? to;
@override@JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) final  CustodySide? toSide;
/// A proposed schedule.
@override final  CustodySchedule? schedule;
@override final  String? note;
@override final  CustodySide proposedBySide;
@override@JsonKey(unknownEnumValue: RequestStatus.closed) final  RequestStatus status;
@override@ServerTimestampConverter() final  DateTime? createdAt;
@override@NullableTimestampConverter() final  DateTime? answeredAt;
@override@JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) final  CustodySide? answeredBySide;
@override final  String? answerNote;

/// Create a copy of ChangeRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChangeRequestCopyWith<_ChangeRequest> get copyWith => __$ChangeRequestCopyWithImpl<_ChangeRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChangeRequestToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChangeRequest&&(identical(other.id, id) || other.id == id)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.from, from) || other.from == from)&&(identical(other.to, to) || other.to == to)&&(identical(other.toSide, toSide) || other.toSide == toSide)&&(identical(other.schedule, schedule) || other.schedule == schedule)&&(identical(other.note, note) || other.note == note)&&(identical(other.proposedBySide, proposedBySide) || other.proposedBySide == proposedBySide)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.answeredAt, answeredAt) || other.answeredAt == answeredAt)&&(identical(other.answeredBySide, answeredBySide) || other.answeredBySide == answeredBySide)&&(identical(other.answerNote, answerNote) || other.answerNote == answerNote));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,kind,from,to,toSide,schedule,note,proposedBySide,status,createdAt,answeredAt,answeredBySide,answerNote);
}

@override
String toString() {
    return 'ChangeRequest(id: $id, kind: $kind, from: $from, to: $to, toSide: $toSide, schedule: $schedule, note: $note, proposedBySide: $proposedBySide, status: $status, createdAt: $createdAt, answeredAt: $answeredAt, answeredBySide: $answeredBySide, answerNote: $answerNote)';
}


}

/// @nodoc
abstract mixin class _$ChangeRequestCopyWith<$Res> implements $ChangeRequestCopyWith<$Res> {
  factory _$ChangeRequestCopyWith(_ChangeRequest value, $Res Function(_ChangeRequest) _then) = __$ChangeRequestCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(includeToJson: false) String id,@JsonKey(unknownEnumValue: ChangeKind.swap) ChangeKind kind,@NullableCalendarDateConverter() CalendarDate? from,@NullableCalendarDateConverter() CalendarDate? to,@JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) CustodySide? toSide, CustodySchedule? schedule, String? note, CustodySide proposedBySide,@JsonKey(unknownEnumValue: RequestStatus.closed) RequestStatus status,@ServerTimestampConverter() DateTime? createdAt,@NullableTimestampConverter() DateTime? answeredAt,@JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) CustodySide? answeredBySide, String? answerNote
});


@override $CustodyScheduleCopyWith<$Res>? get schedule;

}
/// @nodoc
class __$ChangeRequestCopyWithImpl<$Res>
    implements _$ChangeRequestCopyWith<$Res> {
  __$ChangeRequestCopyWithImpl(this._self, this._then);

  final _ChangeRequest _self;
  final $Res Function(_ChangeRequest) _then;

/// Create a copy of ChangeRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? kind = null,Object? from = freezed,Object? to = freezed,Object? toSide = freezed,Object? schedule = freezed,Object? note = freezed,Object? proposedBySide = null,Object? status = null,Object? createdAt = freezed,Object? answeredAt = freezed,Object? answeredBySide = freezed,Object? answerNote = freezed,}) {
  return _then(_ChangeRequest(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as ChangeKind,from: freezed == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as CalendarDate?,to: freezed == to ? _self.to : to // ignore: cast_nullable_to_non_nullable
as CalendarDate?,toSide: freezed == toSide ? _self.toSide : toSide // ignore: cast_nullable_to_non_nullable
as CustodySide?,schedule: freezed == schedule ? _self.schedule : schedule // ignore: cast_nullable_to_non_nullable
as CustodySchedule?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,proposedBySide: null == proposedBySide ? _self.proposedBySide : proposedBySide // ignore: cast_nullable_to_non_nullable
as CustodySide,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as RequestStatus,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,answeredAt: freezed == answeredAt ? _self.answeredAt : answeredAt // ignore: cast_nullable_to_non_nullable
as DateTime?,answeredBySide: freezed == answeredBySide ? _self.answeredBySide : answeredBySide // ignore: cast_nullable_to_non_nullable
as CustodySide?,answerNote: freezed == answerNote ? _self.answerNote : answerNote // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of ChangeRequest
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CustodyScheduleCopyWith<$Res>? get schedule {
    if (_self.schedule == null) {
    return null;
  }

  return $CustodyScheduleCopyWith<$Res>(_self.schedule!, (value) {
    return _then(_self.copyWith(schedule: value));
  });
}
}

// dart format on
