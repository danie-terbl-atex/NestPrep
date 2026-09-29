// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'shift_summary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ShiftSummary {

@JsonKey(includeToJson: false) String get id; String get carerMemberId;@NullableTimestampConverter() DateTime? get startedAt;@NullableTimestampConverter() DateTime? get endedAt; String? get endedBy; Map<String, int> get counts; List<SummaryMoment> get moments; bool get isTrimmed; int get entryCount; int get photoCount; List<String> get childIds; ChecklistProgress get checklist; String? get closingNote;
/// Create a copy of ShiftSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShiftSummaryCopyWith<ShiftSummary> get copyWith => _$ShiftSummaryCopyWithImpl<ShiftSummary>(this as ShiftSummary, _$identity);

  /// Serializes this ShiftSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ShiftSummary;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShiftSummary&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.carerMemberId, _this.carerMemberId) || other.carerMemberId == _this.carerMemberId)&&(identical(other.startedAt, _this.startedAt) || other.startedAt == _this.startedAt)&&(identical(other.endedAt, _this.endedAt) || other.endedAt == _this.endedAt)&&(identical(other.endedBy, _this.endedBy) || other.endedBy == _this.endedBy)&&const DeepCollectionEquality().equals(other.counts, _this.counts)&&const DeepCollectionEquality().equals(other.moments, _this.moments)&&(identical(other.isTrimmed, _this.isTrimmed) || other.isTrimmed == _this.isTrimmed)&&(identical(other.entryCount, _this.entryCount) || other.entryCount == _this.entryCount)&&(identical(other.photoCount, _this.photoCount) || other.photoCount == _this.photoCount)&&const DeepCollectionEquality().equals(other.childIds, _this.childIds)&&(identical(other.checklist, _this.checklist) || other.checklist == _this.checklist)&&(identical(other.closingNote, _this.closingNote) || other.closingNote == _this.closingNote));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ShiftSummary;
  return Object.hash(runtimeType,_this.id,_this.carerMemberId,_this.startedAt,_this.endedAt,_this.endedBy,const DeepCollectionEquality().hash(_this.counts),const DeepCollectionEquality().hash(_this.moments),_this.isTrimmed,_this.entryCount,_this.photoCount,const DeepCollectionEquality().hash(_this.childIds),_this.checklist,_this.closingNote);
}

@override
String toString() {
  final _this = this as ShiftSummary;
  return 'ShiftSummary(id: ${_this.id}, carerMemberId: ${_this.carerMemberId}, startedAt: ${_this.startedAt}, endedAt: ${_this.endedAt}, endedBy: ${_this.endedBy}, counts: ${_this.counts}, moments: ${_this.moments}, isTrimmed: ${_this.isTrimmed}, entryCount: ${_this.entryCount}, photoCount: ${_this.photoCount}, childIds: ${_this.childIds}, checklist: ${_this.checklist}, closingNote: ${_this.closingNote})';
}


}

/// @nodoc
abstract mixin class $ShiftSummaryCopyWith<$Res>  {
  factory $ShiftSummaryCopyWith(ShiftSummary value, $Res Function(ShiftSummary) _then) = _$ShiftSummaryCopyWithImpl;
@useResult
$Res call({
@JsonKey(includeToJson: false) String id, String carerMemberId,@NullableTimestampConverter() DateTime? startedAt,@NullableTimestampConverter() DateTime? endedAt, String? endedBy, Map<String, int> counts, List<SummaryMoment> moments, bool isTrimmed, int entryCount, int photoCount, List<String> childIds, ChecklistProgress checklist, String? closingNote
});


$ChecklistProgressCopyWith<$Res> get checklist;

}
/// @nodoc
class _$ShiftSummaryCopyWithImpl<$Res>
    implements $ShiftSummaryCopyWith<$Res> {
  _$ShiftSummaryCopyWithImpl(this._self, this._then);

  final ShiftSummary _self;
  final $Res Function(ShiftSummary) _then;

/// Create a copy of ShiftSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? carerMemberId = null,Object? startedAt = freezed,Object? endedAt = freezed,Object? endedBy = freezed,Object? counts = null,Object? moments = null,Object? isTrimmed = null,Object? entryCount = null,Object? photoCount = null,Object? childIds = null,Object? checklist = null,Object? closingNote = freezed,}) {
  return _then(ShiftSummary(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,carerMemberId: null == carerMemberId ? _self.carerMemberId : carerMemberId // ignore: cast_nullable_to_non_nullable
as String,startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,endedAt: freezed == endedAt ? _self.endedAt : endedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,endedBy: freezed == endedBy ? _self.endedBy : endedBy // ignore: cast_nullable_to_non_nullable
as String?,counts: null == counts ? _self.counts : counts // ignore: cast_nullable_to_non_nullable
as Map<String, int>,moments: null == moments ? _self.moments : moments // ignore: cast_nullable_to_non_nullable
as List<SummaryMoment>,isTrimmed: null == isTrimmed ? _self.isTrimmed : isTrimmed // ignore: cast_nullable_to_non_nullable
as bool,entryCount: null == entryCount ? _self.entryCount : entryCount // ignore: cast_nullable_to_non_nullable
as int,photoCount: null == photoCount ? _self.photoCount : photoCount // ignore: cast_nullable_to_non_nullable
as int,childIds: null == childIds ? _self.childIds : childIds // ignore: cast_nullable_to_non_nullable
as List<String>,checklist: null == checklist ? _self.checklist : checklist // ignore: cast_nullable_to_non_nullable
as ChecklistProgress,closingNote: freezed == closingNote ? _self.closingNote : closingNote // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of ShiftSummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChecklistProgressCopyWith<$Res> get checklist {
  
  return $ChecklistProgressCopyWith<$Res>(_self.checklist, (value) {
    return _then(_self.copyWith(checklist: value));
  });
}
}


/// Adds pattern-matching-related methods to [ShiftSummary].
extension ShiftSummaryPatterns on ShiftSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ShiftSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ShiftSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ShiftSummary value)  $default,){
final _that = this;
switch (_that) {
case _ShiftSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ShiftSummary value)?  $default,){
final _that = this;
switch (_that) {
case _ShiftSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  String carerMemberId, @NullableTimestampConverter()  DateTime? startedAt, @NullableTimestampConverter()  DateTime? endedAt,  String? endedBy,  Map<String, int> counts,  List<SummaryMoment> moments,  bool isTrimmed,  int entryCount,  int photoCount,  List<String> childIds,  ChecklistProgress checklist,  String? closingNote)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ShiftSummary() when $default != null:
return $default(_that.id,_that.carerMemberId,_that.startedAt,_that.endedAt,_that.endedBy,_that.counts,_that.moments,_that.isTrimmed,_that.entryCount,_that.photoCount,_that.childIds,_that.checklist,_that.closingNote);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  String carerMemberId, @NullableTimestampConverter()  DateTime? startedAt, @NullableTimestampConverter()  DateTime? endedAt,  String? endedBy,  Map<String, int> counts,  List<SummaryMoment> moments,  bool isTrimmed,  int entryCount,  int photoCount,  List<String> childIds,  ChecklistProgress checklist,  String? closingNote)  $default,) {final _that = this;
switch (_that) {
case _ShiftSummary():
return $default(_that.id,_that.carerMemberId,_that.startedAt,_that.endedAt,_that.endedBy,_that.counts,_that.moments,_that.isTrimmed,_that.entryCount,_that.photoCount,_that.childIds,_that.checklist,_that.closingNote);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(includeToJson: false)  String id,  String carerMemberId, @NullableTimestampConverter()  DateTime? startedAt, @NullableTimestampConverter()  DateTime? endedAt,  String? endedBy,  Map<String, int> counts,  List<SummaryMoment> moments,  bool isTrimmed,  int entryCount,  int photoCount,  List<String> childIds,  ChecklistProgress checklist,  String? closingNote)?  $default,) {final _that = this;
switch (_that) {
case _ShiftSummary() when $default != null:
return $default(_that.id,_that.carerMemberId,_that.startedAt,_that.endedAt,_that.endedBy,_that.counts,_that.moments,_that.isTrimmed,_that.entryCount,_that.photoCount,_that.childIds,_that.checklist,_that.closingNote);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ShiftSummary extends ShiftSummary {
  const _ShiftSummary({@JsonKey(includeToJson: false) required this.id, required this.carerMemberId, @NullableTimestampConverter() this.startedAt, @NullableTimestampConverter() this.endedAt, this.endedBy,  Map<String, int> counts = const <String, int>{},  List<SummaryMoment> moments = const <SummaryMoment>[], this.isTrimmed = false, this.entryCount = 0, this.photoCount = 0,  List<String> childIds = const <String>[], this.checklist = const ChecklistProgress(), this.closingNote}): _counts = counts,_moments = moments,_childIds = childIds,super._();
  factory _ShiftSummary.fromJson(Map<String, dynamic> json) => _$ShiftSummaryFromJson(json);

@override@JsonKey(includeToJson: false) final  String id;
@override final  String carerMemberId;
@override@NullableTimestampConverter() final  DateTime? startedAt;
@override@NullableTimestampConverter() final  DateTime? endedAt;
@override final  String? endedBy;
 final  Map<String, int> _counts;
@override@JsonKey() Map<String, int> get counts {
  if (_counts is EqualUnmodifiableMapView) return _counts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_counts);
}

 final  List<SummaryMoment> _moments;
@override@JsonKey() List<SummaryMoment> get moments {
  if (_moments is EqualUnmodifiableListView) return _moments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_moments);
}

@override@JsonKey() final  bool isTrimmed;
@override@JsonKey() final  int entryCount;
@override@JsonKey() final  int photoCount;
 final  List<String> _childIds;
@override@JsonKey() List<String> get childIds {
  if (_childIds is EqualUnmodifiableListView) return _childIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_childIds);
}

@override@JsonKey() final  ChecklistProgress checklist;
@override final  String? closingNote;

/// Create a copy of ShiftSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ShiftSummaryCopyWith<_ShiftSummary> get copyWith => __$ShiftSummaryCopyWithImpl<_ShiftSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ShiftSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ShiftSummary&&(identical(other.id, id) || other.id == id)&&(identical(other.carerMemberId, carerMemberId) || other.carerMemberId == carerMemberId)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.endedAt, endedAt) || other.endedAt == endedAt)&&(identical(other.endedBy, endedBy) || other.endedBy == endedBy)&&const DeepCollectionEquality().equals(other.counts, _counts)&&const DeepCollectionEquality().equals(other.moments, _moments)&&(identical(other.isTrimmed, isTrimmed) || other.isTrimmed == isTrimmed)&&(identical(other.entryCount, entryCount) || other.entryCount == entryCount)&&(identical(other.photoCount, photoCount) || other.photoCount == photoCount)&&const DeepCollectionEquality().equals(other.childIds, _childIds)&&(identical(other.checklist, checklist) || other.checklist == checklist)&&(identical(other.closingNote, closingNote) || other.closingNote == closingNote));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,carerMemberId,startedAt,endedAt,endedBy,const DeepCollectionEquality().hash(_counts),const DeepCollectionEquality().hash(_moments),isTrimmed,entryCount,photoCount,const DeepCollectionEquality().hash(_childIds),checklist,closingNote);
}

@override
String toString() {
    return 'ShiftSummary(id: $id, carerMemberId: $carerMemberId, startedAt: $startedAt, endedAt: $endedAt, endedBy: $endedBy, counts: $counts, moments: $moments, isTrimmed: $isTrimmed, entryCount: $entryCount, photoCount: $photoCount, childIds: $childIds, checklist: $checklist, closingNote: $closingNote)';
}


}

/// @nodoc
abstract mixin class _$ShiftSummaryCopyWith<$Res> implements $ShiftSummaryCopyWith<$Res> {
  factory _$ShiftSummaryCopyWith(_ShiftSummary value, $Res Function(_ShiftSummary) _then) = __$ShiftSummaryCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(includeToJson: false) String id, String carerMemberId,@NullableTimestampConverter() DateTime? startedAt,@NullableTimestampConverter() DateTime? endedAt, String? endedBy, Map<String, int> counts, List<SummaryMoment> moments, bool isTrimmed, int entryCount, int photoCount, List<String> childIds, ChecklistProgress checklist, String? closingNote
});


@override $ChecklistProgressCopyWith<$Res> get checklist;

}
/// @nodoc
class __$ShiftSummaryCopyWithImpl<$Res>
    implements _$ShiftSummaryCopyWith<$Res> {
  __$ShiftSummaryCopyWithImpl(this._self, this._then);

  final _ShiftSummary _self;
  final $Res Function(_ShiftSummary) _then;

/// Create a copy of ShiftSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? carerMemberId = null,Object? startedAt = freezed,Object? endedAt = freezed,Object? endedBy = freezed,Object? counts = null,Object? moments = null,Object? isTrimmed = null,Object? entryCount = null,Object? photoCount = null,Object? childIds = null,Object? checklist = null,Object? closingNote = freezed,}) {
  return _then(_ShiftSummary(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,carerMemberId: null == carerMemberId ? _self.carerMemberId : carerMemberId // ignore: cast_nullable_to_non_nullable
as String,startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,endedAt: freezed == endedAt ? _self.endedAt : endedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,endedBy: freezed == endedBy ? _self.endedBy : endedBy // ignore: cast_nullable_to_non_nullable
as String?,counts: null == counts ? _self._counts : counts // ignore: cast_nullable_to_non_nullable
as Map<String, int>,moments: null == moments ? _self._moments : moments // ignore: cast_nullable_to_non_nullable
as List<SummaryMoment>,isTrimmed: null == isTrimmed ? _self.isTrimmed : isTrimmed // ignore: cast_nullable_to_non_nullable
as bool,entryCount: null == entryCount ? _self.entryCount : entryCount // ignore: cast_nullable_to_non_nullable
as int,photoCount: null == photoCount ? _self.photoCount : photoCount // ignore: cast_nullable_to_non_nullable
as int,childIds: null == childIds ? _self._childIds : childIds // ignore: cast_nullable_to_non_nullable
as List<String>,checklist: null == checklist ? _self.checklist : checklist // ignore: cast_nullable_to_non_nullable
as ChecklistProgress,closingNote: freezed == closingNote ? _self.closingNote : closingNote // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of ShiftSummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChecklistProgressCopyWith<$Res> get checklist {
  
  return $ChecklistProgressCopyWith<$Res>(_self.checklist, (value) {
    return _then(_self.copyWith(checklist: value));
  });
}
}

// dart format on
