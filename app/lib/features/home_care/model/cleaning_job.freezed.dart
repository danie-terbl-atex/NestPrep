// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'cleaning_job.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CleaningJob {

@JsonKey(includeToJson: false) String get id; String get title; String get roomId;/// The member profile doing it — claimed or not. What `own` means.
 String get helperId;/// A day in the household's zone, never an instant (`ENG-21`).
@CalendarDateConverter() CalendarDate get dueDate; String? get note; List<String> get productIds; List<JobStep> get steps; List<String> get doneStepIds; JobPhoto get beforePhoto; List<SpotMark> get marks; JobPhoto? get afterPhoto;@JsonKey(unknownEnumValue: JobStatus.assigned) JobStatus get status;/// The latest send-back note, which the helper reads until she hands the
/// job in again. The history keeps every one.
 String? get reviewNote; int get revision; String get createdBy;@ServerTimestampConverter() DateTime? get createdAt;@ServerTimestampConverter() DateTime? get updatedAt;
/// Create a copy of CleaningJob
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CleaningJobCopyWith<CleaningJob> get copyWith => _$CleaningJobCopyWithImpl<CleaningJob>(this as CleaningJob, _$identity);

  /// Serializes this CleaningJob to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as CleaningJob;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CleaningJob&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.roomId, _this.roomId) || other.roomId == _this.roomId)&&(identical(other.helperId, _this.helperId) || other.helperId == _this.helperId)&&(identical(other.dueDate, _this.dueDate) || other.dueDate == _this.dueDate)&&(identical(other.note, _this.note) || other.note == _this.note)&&const DeepCollectionEquality().equals(other.productIds, _this.productIds)&&const DeepCollectionEquality().equals(other.steps, _this.steps)&&const DeepCollectionEquality().equals(other.doneStepIds, _this.doneStepIds)&&(identical(other.beforePhoto, _this.beforePhoto) || other.beforePhoto == _this.beforePhoto)&&const DeepCollectionEquality().equals(other.marks, _this.marks)&&(identical(other.afterPhoto, _this.afterPhoto) || other.afterPhoto == _this.afterPhoto)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.reviewNote, _this.reviewNote) || other.reviewNote == _this.reviewNote)&&(identical(other.revision, _this.revision) || other.revision == _this.revision)&&(identical(other.createdBy, _this.createdBy) || other.createdBy == _this.createdBy)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CleaningJob;
  return Object.hash(runtimeType,_this.id,_this.title,_this.roomId,_this.helperId,_this.dueDate,_this.note,const DeepCollectionEquality().hash(_this.productIds),const DeepCollectionEquality().hash(_this.steps),const DeepCollectionEquality().hash(_this.doneStepIds),_this.beforePhoto,const DeepCollectionEquality().hash(_this.marks),_this.afterPhoto,_this.status,_this.reviewNote,_this.revision,_this.createdBy,_this.createdAt,_this.updatedAt);
}

@override
String toString() {
  final _this = this as CleaningJob;
  return 'CleaningJob(id: ${_this.id}, title: ${_this.title}, roomId: ${_this.roomId}, helperId: ${_this.helperId}, dueDate: ${_this.dueDate}, note: ${_this.note}, productIds: ${_this.productIds}, steps: ${_this.steps}, doneStepIds: ${_this.doneStepIds}, beforePhoto: ${_this.beforePhoto}, marks: ${_this.marks}, afterPhoto: ${_this.afterPhoto}, status: ${_this.status}, reviewNote: ${_this.reviewNote}, revision: ${_this.revision}, createdBy: ${_this.createdBy}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt})';
}


}

/// @nodoc
abstract mixin class $CleaningJobCopyWith<$Res>  {
  factory $CleaningJobCopyWith(CleaningJob value, $Res Function(CleaningJob) _then) = _$CleaningJobCopyWithImpl;
@useResult
$Res call({
@JsonKey(includeToJson: false) String id, String title, String roomId, String helperId,@CalendarDateConverter() CalendarDate dueDate, String? note, List<String> productIds, List<JobStep> steps, List<String> doneStepIds, JobPhoto beforePhoto, List<SpotMark> marks, JobPhoto? afterPhoto,@JsonKey(unknownEnumValue: JobStatus.assigned) JobStatus status, String? reviewNote, int revision, String createdBy,@ServerTimestampConverter() DateTime? createdAt,@ServerTimestampConverter() DateTime? updatedAt
});


$JobPhotoCopyWith<$Res> get beforePhoto;$JobPhotoCopyWith<$Res>? get afterPhoto;

}
/// @nodoc
class _$CleaningJobCopyWithImpl<$Res>
    implements $CleaningJobCopyWith<$Res> {
  _$CleaningJobCopyWithImpl(this._self, this._then);

  final CleaningJob _self;
  final $Res Function(CleaningJob) _then;

/// Create a copy of CleaningJob
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? roomId = null,Object? helperId = null,Object? dueDate = null,Object? note = freezed,Object? productIds = null,Object? steps = null,Object? doneStepIds = null,Object? beforePhoto = null,Object? marks = null,Object? afterPhoto = freezed,Object? status = null,Object? reviewNote = freezed,Object? revision = null,Object? createdBy = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(CleaningJob(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,roomId: null == roomId ? _self.roomId : roomId // ignore: cast_nullable_to_non_nullable
as String,helperId: null == helperId ? _self.helperId : helperId // ignore: cast_nullable_to_non_nullable
as String,dueDate: null == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as CalendarDate,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,productIds: null == productIds ? _self.productIds : productIds // ignore: cast_nullable_to_non_nullable
as List<String>,steps: null == steps ? _self.steps : steps // ignore: cast_nullable_to_non_nullable
as List<JobStep>,doneStepIds: null == doneStepIds ? _self.doneStepIds : doneStepIds // ignore: cast_nullable_to_non_nullable
as List<String>,beforePhoto: null == beforePhoto ? _self.beforePhoto : beforePhoto // ignore: cast_nullable_to_non_nullable
as JobPhoto,marks: null == marks ? _self.marks : marks // ignore: cast_nullable_to_non_nullable
as List<SpotMark>,afterPhoto: freezed == afterPhoto ? _self.afterPhoto : afterPhoto // ignore: cast_nullable_to_non_nullable
as JobPhoto?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as JobStatus,reviewNote: freezed == reviewNote ? _self.reviewNote : reviewNote // ignore: cast_nullable_to_non_nullable
as String?,revision: null == revision ? _self.revision : revision // ignore: cast_nullable_to_non_nullable
as int,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of CleaningJob
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$JobPhotoCopyWith<$Res> get beforePhoto {
  
  return $JobPhotoCopyWith<$Res>(_self.beforePhoto, (value) {
    return _then(_self.copyWith(beforePhoto: value));
  });
}/// Create a copy of CleaningJob
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$JobPhotoCopyWith<$Res>? get afterPhoto {
    if (_self.afterPhoto == null) {
    return null;
  }

  return $JobPhotoCopyWith<$Res>(_self.afterPhoto!, (value) {
    return _then(_self.copyWith(afterPhoto: value));
  });
}
}


/// Adds pattern-matching-related methods to [CleaningJob].
extension CleaningJobPatterns on CleaningJob {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CleaningJob value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CleaningJob() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CleaningJob value)  $default,){
final _that = this;
switch (_that) {
case _CleaningJob():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CleaningJob value)?  $default,){
final _that = this;
switch (_that) {
case _CleaningJob() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  String title,  String roomId,  String helperId, @CalendarDateConverter()  CalendarDate dueDate,  String? note,  List<String> productIds,  List<JobStep> steps,  List<String> doneStepIds,  JobPhoto beforePhoto,  List<SpotMark> marks,  JobPhoto? afterPhoto, @JsonKey(unknownEnumValue: JobStatus.assigned)  JobStatus status,  String? reviewNote,  int revision,  String createdBy, @ServerTimestampConverter()  DateTime? createdAt, @ServerTimestampConverter()  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CleaningJob() when $default != null:
return $default(_that.id,_that.title,_that.roomId,_that.helperId,_that.dueDate,_that.note,_that.productIds,_that.steps,_that.doneStepIds,_that.beforePhoto,_that.marks,_that.afterPhoto,_that.status,_that.reviewNote,_that.revision,_that.createdBy,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  String title,  String roomId,  String helperId, @CalendarDateConverter()  CalendarDate dueDate,  String? note,  List<String> productIds,  List<JobStep> steps,  List<String> doneStepIds,  JobPhoto beforePhoto,  List<SpotMark> marks,  JobPhoto? afterPhoto, @JsonKey(unknownEnumValue: JobStatus.assigned)  JobStatus status,  String? reviewNote,  int revision,  String createdBy, @ServerTimestampConverter()  DateTime? createdAt, @ServerTimestampConverter()  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _CleaningJob():
return $default(_that.id,_that.title,_that.roomId,_that.helperId,_that.dueDate,_that.note,_that.productIds,_that.steps,_that.doneStepIds,_that.beforePhoto,_that.marks,_that.afterPhoto,_that.status,_that.reviewNote,_that.revision,_that.createdBy,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(includeToJson: false)  String id,  String title,  String roomId,  String helperId, @CalendarDateConverter()  CalendarDate dueDate,  String? note,  List<String> productIds,  List<JobStep> steps,  List<String> doneStepIds,  JobPhoto beforePhoto,  List<SpotMark> marks,  JobPhoto? afterPhoto, @JsonKey(unknownEnumValue: JobStatus.assigned)  JobStatus status,  String? reviewNote,  int revision,  String createdBy, @ServerTimestampConverter()  DateTime? createdAt, @ServerTimestampConverter()  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _CleaningJob() when $default != null:
return $default(_that.id,_that.title,_that.roomId,_that.helperId,_that.dueDate,_that.note,_that.productIds,_that.steps,_that.doneStepIds,_that.beforePhoto,_that.marks,_that.afterPhoto,_that.status,_that.reviewNote,_that.revision,_that.createdBy,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CleaningJob extends CleaningJob {
  const _CleaningJob({@JsonKey(includeToJson: false) required this.id, required this.title, required this.roomId, required this.helperId, @CalendarDateConverter() required this.dueDate, this.note,  List<String> productIds = const <String>[],  List<JobStep> steps = const <JobStep>[],  List<String> doneStepIds = const <String>[], required this.beforePhoto,  List<SpotMark> marks = const <SpotMark>[], this.afterPhoto, @JsonKey(unknownEnumValue: JobStatus.assigned) this.status = JobStatus.assigned, this.reviewNote, this.revision = 0, required this.createdBy, @ServerTimestampConverter() this.createdAt, @ServerTimestampConverter() this.updatedAt}): _productIds = productIds,_steps = steps,_doneStepIds = doneStepIds,_marks = marks,super._();
  factory _CleaningJob.fromJson(Map<String, dynamic> json) => _$CleaningJobFromJson(json);

@override@JsonKey(includeToJson: false) final  String id;
@override final  String title;
@override final  String roomId;
/// The member profile doing it — claimed or not. What `own` means.
@override final  String helperId;
/// A day in the household's zone, never an instant (`ENG-21`).
@override@CalendarDateConverter() final  CalendarDate dueDate;
@override final  String? note;
 final  List<String> _productIds;
@override@JsonKey() List<String> get productIds {
  if (_productIds is EqualUnmodifiableListView) return _productIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_productIds);
}

 final  List<JobStep> _steps;
@override@JsonKey() List<JobStep> get steps {
  if (_steps is EqualUnmodifiableListView) return _steps;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_steps);
}

 final  List<String> _doneStepIds;
@override@JsonKey() List<String> get doneStepIds {
  if (_doneStepIds is EqualUnmodifiableListView) return _doneStepIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_doneStepIds);
}

@override final  JobPhoto beforePhoto;
 final  List<SpotMark> _marks;
@override@JsonKey() List<SpotMark> get marks {
  if (_marks is EqualUnmodifiableListView) return _marks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_marks);
}

@override final  JobPhoto? afterPhoto;
@override@JsonKey(unknownEnumValue: JobStatus.assigned) final  JobStatus status;
/// The latest send-back note, which the helper reads until she hands the
/// job in again. The history keeps every one.
@override final  String? reviewNote;
@override@JsonKey() final  int revision;
@override final  String createdBy;
@override@ServerTimestampConverter() final  DateTime? createdAt;
@override@ServerTimestampConverter() final  DateTime? updatedAt;

/// Create a copy of CleaningJob
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CleaningJobCopyWith<_CleaningJob> get copyWith => __$CleaningJobCopyWithImpl<_CleaningJob>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CleaningJobToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CleaningJob&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.roomId, roomId) || other.roomId == roomId)&&(identical(other.helperId, helperId) || other.helperId == helperId)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&(identical(other.note, note) || other.note == note)&&const DeepCollectionEquality().equals(other.productIds, _productIds)&&const DeepCollectionEquality().equals(other.steps, _steps)&&const DeepCollectionEquality().equals(other.doneStepIds, _doneStepIds)&&(identical(other.beforePhoto, beforePhoto) || other.beforePhoto == beforePhoto)&&const DeepCollectionEquality().equals(other.marks, _marks)&&(identical(other.afterPhoto, afterPhoto) || other.afterPhoto == afterPhoto)&&(identical(other.status, status) || other.status == status)&&(identical(other.reviewNote, reviewNote) || other.reviewNote == reviewNote)&&(identical(other.revision, revision) || other.revision == revision)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,title,roomId,helperId,dueDate,note,const DeepCollectionEquality().hash(_productIds),const DeepCollectionEquality().hash(_steps),const DeepCollectionEquality().hash(_doneStepIds),beforePhoto,const DeepCollectionEquality().hash(_marks),afterPhoto,status,reviewNote,revision,createdBy,createdAt,updatedAt);
}

@override
String toString() {
    return 'CleaningJob(id: $id, title: $title, roomId: $roomId, helperId: $helperId, dueDate: $dueDate, note: $note, productIds: $productIds, steps: $steps, doneStepIds: $doneStepIds, beforePhoto: $beforePhoto, marks: $marks, afterPhoto: $afterPhoto, status: $status, reviewNote: $reviewNote, revision: $revision, createdBy: $createdBy, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$CleaningJobCopyWith<$Res> implements $CleaningJobCopyWith<$Res> {
  factory _$CleaningJobCopyWith(_CleaningJob value, $Res Function(_CleaningJob) _then) = __$CleaningJobCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(includeToJson: false) String id, String title, String roomId, String helperId,@CalendarDateConverter() CalendarDate dueDate, String? note, List<String> productIds, List<JobStep> steps, List<String> doneStepIds, JobPhoto beforePhoto, List<SpotMark> marks, JobPhoto? afterPhoto,@JsonKey(unknownEnumValue: JobStatus.assigned) JobStatus status, String? reviewNote, int revision, String createdBy,@ServerTimestampConverter() DateTime? createdAt,@ServerTimestampConverter() DateTime? updatedAt
});


@override $JobPhotoCopyWith<$Res> get beforePhoto;@override $JobPhotoCopyWith<$Res>? get afterPhoto;

}
/// @nodoc
class __$CleaningJobCopyWithImpl<$Res>
    implements _$CleaningJobCopyWith<$Res> {
  __$CleaningJobCopyWithImpl(this._self, this._then);

  final _CleaningJob _self;
  final $Res Function(_CleaningJob) _then;

/// Create a copy of CleaningJob
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? roomId = null,Object? helperId = null,Object? dueDate = null,Object? note = freezed,Object? productIds = null,Object? steps = null,Object? doneStepIds = null,Object? beforePhoto = null,Object? marks = null,Object? afterPhoto = freezed,Object? status = null,Object? reviewNote = freezed,Object? revision = null,Object? createdBy = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_CleaningJob(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,roomId: null == roomId ? _self.roomId : roomId // ignore: cast_nullable_to_non_nullable
as String,helperId: null == helperId ? _self.helperId : helperId // ignore: cast_nullable_to_non_nullable
as String,dueDate: null == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as CalendarDate,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,productIds: null == productIds ? _self._productIds : productIds // ignore: cast_nullable_to_non_nullable
as List<String>,steps: null == steps ? _self._steps : steps // ignore: cast_nullable_to_non_nullable
as List<JobStep>,doneStepIds: null == doneStepIds ? _self._doneStepIds : doneStepIds // ignore: cast_nullable_to_non_nullable
as List<String>,beforePhoto: null == beforePhoto ? _self.beforePhoto : beforePhoto // ignore: cast_nullable_to_non_nullable
as JobPhoto,marks: null == marks ? _self._marks : marks // ignore: cast_nullable_to_non_nullable
as List<SpotMark>,afterPhoto: freezed == afterPhoto ? _self.afterPhoto : afterPhoto // ignore: cast_nullable_to_non_nullable
as JobPhoto?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as JobStatus,reviewNote: freezed == reviewNote ? _self.reviewNote : reviewNote // ignore: cast_nullable_to_non_nullable
as String?,revision: null == revision ? _self.revision : revision // ignore: cast_nullable_to_non_nullable
as int,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of CleaningJob
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$JobPhotoCopyWith<$Res> get beforePhoto {
  
  return $JobPhotoCopyWith<$Res>(_self.beforePhoto, (value) {
    return _then(_self.copyWith(beforePhoto: value));
  });
}/// Create a copy of CleaningJob
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$JobPhotoCopyWith<$Res>? get afterPhoto {
    if (_self.afterPhoto == null) {
    return null;
  }

  return $JobPhotoCopyWith<$Res>(_self.afterPhoto!, (value) {
    return _then(_self.copyWith(afterPhoto: value));
  });
}
}

// dart format on
