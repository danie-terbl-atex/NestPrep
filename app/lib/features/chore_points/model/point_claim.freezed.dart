// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'point_claim.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PointClaim {

@JsonKey(includeToJson: false) String get id; String get memberId; String get taskId;@CalendarDateConverter() CalendarDate get occurrenceDate; String get title; int get points;/// A status a newer build wrote reads as withdrawn: owed nothing, shown
/// nothing (`BE-10`).
@JsonKey(unknownEnumValue: ClaimStatus.withdrawn) ClaimStatus get status; int get round;@NullableTimestampConverter() DateTime? get claimedAt;
/// Create a copy of PointClaim
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PointClaimCopyWith<PointClaim> get copyWith => _$PointClaimCopyWithImpl<PointClaim>(this as PointClaim, _$identity);

  /// Serializes this PointClaim to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PointClaim;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PointClaim&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.memberId, _this.memberId) || other.memberId == _this.memberId)&&(identical(other.taskId, _this.taskId) || other.taskId == _this.taskId)&&(identical(other.occurrenceDate, _this.occurrenceDate) || other.occurrenceDate == _this.occurrenceDate)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.points, _this.points) || other.points == _this.points)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.round, _this.round) || other.round == _this.round)&&(identical(other.claimedAt, _this.claimedAt) || other.claimedAt == _this.claimedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PointClaim;
  return Object.hash(runtimeType,_this.id,_this.memberId,_this.taskId,_this.occurrenceDate,_this.title,_this.points,_this.status,_this.round,_this.claimedAt);
}

@override
String toString() {
  final _this = this as PointClaim;
  return 'PointClaim(id: ${_this.id}, memberId: ${_this.memberId}, taskId: ${_this.taskId}, occurrenceDate: ${_this.occurrenceDate}, title: ${_this.title}, points: ${_this.points}, status: ${_this.status}, round: ${_this.round}, claimedAt: ${_this.claimedAt})';
}


}

/// @nodoc
abstract mixin class $PointClaimCopyWith<$Res>  {
  factory $PointClaimCopyWith(PointClaim value, $Res Function(PointClaim) _then) = _$PointClaimCopyWithImpl;
@useResult
$Res call({
@JsonKey(includeToJson: false) String id, String memberId, String taskId,@CalendarDateConverter() CalendarDate occurrenceDate, String title, int points,@JsonKey(unknownEnumValue: ClaimStatus.withdrawn) ClaimStatus status, int round,@NullableTimestampConverter() DateTime? claimedAt
});




}
/// @nodoc
class _$PointClaimCopyWithImpl<$Res>
    implements $PointClaimCopyWith<$Res> {
  _$PointClaimCopyWithImpl(this._self, this._then);

  final PointClaim _self;
  final $Res Function(PointClaim) _then;

/// Create a copy of PointClaim
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? memberId = null,Object? taskId = null,Object? occurrenceDate = null,Object? title = null,Object? points = null,Object? status = null,Object? round = null,Object? claimedAt = freezed,}) {
  return _then(PointClaim(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,memberId: null == memberId ? _self.memberId : memberId // ignore: cast_nullable_to_non_nullable
as String,taskId: null == taskId ? _self.taskId : taskId // ignore: cast_nullable_to_non_nullable
as String,occurrenceDate: null == occurrenceDate ? _self.occurrenceDate : occurrenceDate // ignore: cast_nullable_to_non_nullable
as CalendarDate,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,points: null == points ? _self.points : points // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ClaimStatus,round: null == round ? _self.round : round // ignore: cast_nullable_to_non_nullable
as int,claimedAt: freezed == claimedAt ? _self.claimedAt : claimedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [PointClaim].
extension PointClaimPatterns on PointClaim {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PointClaim value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PointClaim() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PointClaim value)  $default,){
final _that = this;
switch (_that) {
case _PointClaim():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PointClaim value)?  $default,){
final _that = this;
switch (_that) {
case _PointClaim() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  String memberId,  String taskId, @CalendarDateConverter()  CalendarDate occurrenceDate,  String title,  int points, @JsonKey(unknownEnumValue: ClaimStatus.withdrawn)  ClaimStatus status,  int round, @NullableTimestampConverter()  DateTime? claimedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PointClaim() when $default != null:
return $default(_that.id,_that.memberId,_that.taskId,_that.occurrenceDate,_that.title,_that.points,_that.status,_that.round,_that.claimedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  String memberId,  String taskId, @CalendarDateConverter()  CalendarDate occurrenceDate,  String title,  int points, @JsonKey(unknownEnumValue: ClaimStatus.withdrawn)  ClaimStatus status,  int round, @NullableTimestampConverter()  DateTime? claimedAt)  $default,) {final _that = this;
switch (_that) {
case _PointClaim():
return $default(_that.id,_that.memberId,_that.taskId,_that.occurrenceDate,_that.title,_that.points,_that.status,_that.round,_that.claimedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(includeToJson: false)  String id,  String memberId,  String taskId, @CalendarDateConverter()  CalendarDate occurrenceDate,  String title,  int points, @JsonKey(unknownEnumValue: ClaimStatus.withdrawn)  ClaimStatus status,  int round, @NullableTimestampConverter()  DateTime? claimedAt)?  $default,) {final _that = this;
switch (_that) {
case _PointClaim() when $default != null:
return $default(_that.id,_that.memberId,_that.taskId,_that.occurrenceDate,_that.title,_that.points,_that.status,_that.round,_that.claimedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PointClaim extends PointClaim {
  const _PointClaim({@JsonKey(includeToJson: false) required this.id, required this.memberId, required this.taskId, @CalendarDateConverter() required this.occurrenceDate, required this.title, required this.points, @JsonKey(unknownEnumValue: ClaimStatus.withdrawn) required this.status, this.round = 1, @NullableTimestampConverter() this.claimedAt}): super._();
  factory _PointClaim.fromJson(Map<String, dynamic> json) => _$PointClaimFromJson(json);

@override@JsonKey(includeToJson: false) final  String id;
@override final  String memberId;
@override final  String taskId;
@override@CalendarDateConverter() final  CalendarDate occurrenceDate;
@override final  String title;
@override final  int points;
/// A status a newer build wrote reads as withdrawn: owed nothing, shown
/// nothing (`BE-10`).
@override@JsonKey(unknownEnumValue: ClaimStatus.withdrawn) final  ClaimStatus status;
@override@JsonKey() final  int round;
@override@NullableTimestampConverter() final  DateTime? claimedAt;

/// Create a copy of PointClaim
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PointClaimCopyWith<_PointClaim> get copyWith => __$PointClaimCopyWithImpl<_PointClaim>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PointClaimToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PointClaim&&(identical(other.id, id) || other.id == id)&&(identical(other.memberId, memberId) || other.memberId == memberId)&&(identical(other.taskId, taskId) || other.taskId == taskId)&&(identical(other.occurrenceDate, occurrenceDate) || other.occurrenceDate == occurrenceDate)&&(identical(other.title, title) || other.title == title)&&(identical(other.points, points) || other.points == points)&&(identical(other.status, status) || other.status == status)&&(identical(other.round, round) || other.round == round)&&(identical(other.claimedAt, claimedAt) || other.claimedAt == claimedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,memberId,taskId,occurrenceDate,title,points,status,round,claimedAt);
}

@override
String toString() {
    return 'PointClaim(id: $id, memberId: $memberId, taskId: $taskId, occurrenceDate: $occurrenceDate, title: $title, points: $points, status: $status, round: $round, claimedAt: $claimedAt)';
}


}

/// @nodoc
abstract mixin class _$PointClaimCopyWith<$Res> implements $PointClaimCopyWith<$Res> {
  factory _$PointClaimCopyWith(_PointClaim value, $Res Function(_PointClaim) _then) = __$PointClaimCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(includeToJson: false) String id, String memberId, String taskId,@CalendarDateConverter() CalendarDate occurrenceDate, String title, int points,@JsonKey(unknownEnumValue: ClaimStatus.withdrawn) ClaimStatus status, int round,@NullableTimestampConverter() DateTime? claimedAt
});




}
/// @nodoc
class __$PointClaimCopyWithImpl<$Res>
    implements _$PointClaimCopyWith<$Res> {
  __$PointClaimCopyWithImpl(this._self, this._then);

  final _PointClaim _self;
  final $Res Function(_PointClaim) _then;

/// Create a copy of PointClaim
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? memberId = null,Object? taskId = null,Object? occurrenceDate = null,Object? title = null,Object? points = null,Object? status = null,Object? round = null,Object? claimedAt = freezed,}) {
  return _then(_PointClaim(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,memberId: null == memberId ? _self.memberId : memberId // ignore: cast_nullable_to_non_nullable
as String,taskId: null == taskId ? _self.taskId : taskId // ignore: cast_nullable_to_non_nullable
as String,occurrenceDate: null == occurrenceDate ? _self.occurrenceDate : occurrenceDate // ignore: cast_nullable_to_non_nullable
as CalendarDate,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,points: null == points ? _self.points : points // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ClaimStatus,round: null == round ? _self.round : round // ignore: cast_nullable_to_non_nullable
as int,claimedAt: freezed == claimedAt ? _self.claimedAt : claimedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
