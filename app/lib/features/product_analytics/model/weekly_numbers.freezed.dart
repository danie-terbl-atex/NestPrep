// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'weekly_numbers.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WeeklyNumbers {

/// The ISO week, `YYYY-Www` — also the document id.
 String get week;/// The Monday the week starts on.
@CalendarDateConverter() CalendarDate get weekStart;/// The north star: families where two or more people used NestPrep.
 int get activeFamilies;/// Families where anybody did — what [activeFamilies] is read against.
 int get familiesSeen; int get lunchPlansCreated; int get familiesPlanningLunches;/// Families created this week: the invite cohort.
 int get newFamilies; int get newFamiliesInvitingAnAdult;/// False until every family in the cohort has had its first seven days.
 bool get isInviteCohortComplete;@NullableTimestampConverter() DateTime? get computedAt;
/// Create a copy of WeeklyNumbers
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WeeklyNumbersCopyWith<WeeklyNumbers> get copyWith => _$WeeklyNumbersCopyWithImpl<WeeklyNumbers>(this as WeeklyNumbers, _$identity);

  /// Serializes this WeeklyNumbers to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as WeeklyNumbers;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WeeklyNumbers&&(identical(other.week, _this.week) || other.week == _this.week)&&(identical(other.weekStart, _this.weekStart) || other.weekStart == _this.weekStart)&&(identical(other.activeFamilies, _this.activeFamilies) || other.activeFamilies == _this.activeFamilies)&&(identical(other.familiesSeen, _this.familiesSeen) || other.familiesSeen == _this.familiesSeen)&&(identical(other.lunchPlansCreated, _this.lunchPlansCreated) || other.lunchPlansCreated == _this.lunchPlansCreated)&&(identical(other.familiesPlanningLunches, _this.familiesPlanningLunches) || other.familiesPlanningLunches == _this.familiesPlanningLunches)&&(identical(other.newFamilies, _this.newFamilies) || other.newFamilies == _this.newFamilies)&&(identical(other.newFamiliesInvitingAnAdult, _this.newFamiliesInvitingAnAdult) || other.newFamiliesInvitingAnAdult == _this.newFamiliesInvitingAnAdult)&&(identical(other.isInviteCohortComplete, _this.isInviteCohortComplete) || other.isInviteCohortComplete == _this.isInviteCohortComplete)&&(identical(other.computedAt, _this.computedAt) || other.computedAt == _this.computedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as WeeklyNumbers;
  return Object.hash(runtimeType,_this.week,_this.weekStart,_this.activeFamilies,_this.familiesSeen,_this.lunchPlansCreated,_this.familiesPlanningLunches,_this.newFamilies,_this.newFamiliesInvitingAnAdult,_this.isInviteCohortComplete,_this.computedAt);
}

@override
String toString() {
  final _this = this as WeeklyNumbers;
  return 'WeeklyNumbers(week: ${_this.week}, weekStart: ${_this.weekStart}, activeFamilies: ${_this.activeFamilies}, familiesSeen: ${_this.familiesSeen}, lunchPlansCreated: ${_this.lunchPlansCreated}, familiesPlanningLunches: ${_this.familiesPlanningLunches}, newFamilies: ${_this.newFamilies}, newFamiliesInvitingAnAdult: ${_this.newFamiliesInvitingAnAdult}, isInviteCohortComplete: ${_this.isInviteCohortComplete}, computedAt: ${_this.computedAt})';
}


}

/// @nodoc
abstract mixin class $WeeklyNumbersCopyWith<$Res>  {
  factory $WeeklyNumbersCopyWith(WeeklyNumbers value, $Res Function(WeeklyNumbers) _then) = _$WeeklyNumbersCopyWithImpl;
@useResult
$Res call({
 String week,@CalendarDateConverter() CalendarDate weekStart, int activeFamilies, int familiesSeen, int lunchPlansCreated, int familiesPlanningLunches, int newFamilies, int newFamiliesInvitingAnAdult, bool isInviteCohortComplete,@NullableTimestampConverter() DateTime? computedAt
});




}
/// @nodoc
class _$WeeklyNumbersCopyWithImpl<$Res>
    implements $WeeklyNumbersCopyWith<$Res> {
  _$WeeklyNumbersCopyWithImpl(this._self, this._then);

  final WeeklyNumbers _self;
  final $Res Function(WeeklyNumbers) _then;

/// Create a copy of WeeklyNumbers
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? week = null,Object? weekStart = null,Object? activeFamilies = null,Object? familiesSeen = null,Object? lunchPlansCreated = null,Object? familiesPlanningLunches = null,Object? newFamilies = null,Object? newFamiliesInvitingAnAdult = null,Object? isInviteCohortComplete = null,Object? computedAt = freezed,}) {
  return _then(WeeklyNumbers(
week: null == week ? _self.week : week // ignore: cast_nullable_to_non_nullable
as String,weekStart: null == weekStart ? _self.weekStart : weekStart // ignore: cast_nullable_to_non_nullable
as CalendarDate,activeFamilies: null == activeFamilies ? _self.activeFamilies : activeFamilies // ignore: cast_nullable_to_non_nullable
as int,familiesSeen: null == familiesSeen ? _self.familiesSeen : familiesSeen // ignore: cast_nullable_to_non_nullable
as int,lunchPlansCreated: null == lunchPlansCreated ? _self.lunchPlansCreated : lunchPlansCreated // ignore: cast_nullable_to_non_nullable
as int,familiesPlanningLunches: null == familiesPlanningLunches ? _self.familiesPlanningLunches : familiesPlanningLunches // ignore: cast_nullable_to_non_nullable
as int,newFamilies: null == newFamilies ? _self.newFamilies : newFamilies // ignore: cast_nullable_to_non_nullable
as int,newFamiliesInvitingAnAdult: null == newFamiliesInvitingAnAdult ? _self.newFamiliesInvitingAnAdult : newFamiliesInvitingAnAdult // ignore: cast_nullable_to_non_nullable
as int,isInviteCohortComplete: null == isInviteCohortComplete ? _self.isInviteCohortComplete : isInviteCohortComplete // ignore: cast_nullable_to_non_nullable
as bool,computedAt: freezed == computedAt ? _self.computedAt : computedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [WeeklyNumbers].
extension WeeklyNumbersPatterns on WeeklyNumbers {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WeeklyNumbers value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WeeklyNumbers() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WeeklyNumbers value)  $default,){
final _that = this;
switch (_that) {
case _WeeklyNumbers():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WeeklyNumbers value)?  $default,){
final _that = this;
switch (_that) {
case _WeeklyNumbers() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String week, @CalendarDateConverter()  CalendarDate weekStart,  int activeFamilies,  int familiesSeen,  int lunchPlansCreated,  int familiesPlanningLunches,  int newFamilies,  int newFamiliesInvitingAnAdult,  bool isInviteCohortComplete, @NullableTimestampConverter()  DateTime? computedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WeeklyNumbers() when $default != null:
return $default(_that.week,_that.weekStart,_that.activeFamilies,_that.familiesSeen,_that.lunchPlansCreated,_that.familiesPlanningLunches,_that.newFamilies,_that.newFamiliesInvitingAnAdult,_that.isInviteCohortComplete,_that.computedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String week, @CalendarDateConverter()  CalendarDate weekStart,  int activeFamilies,  int familiesSeen,  int lunchPlansCreated,  int familiesPlanningLunches,  int newFamilies,  int newFamiliesInvitingAnAdult,  bool isInviteCohortComplete, @NullableTimestampConverter()  DateTime? computedAt)  $default,) {final _that = this;
switch (_that) {
case _WeeklyNumbers():
return $default(_that.week,_that.weekStart,_that.activeFamilies,_that.familiesSeen,_that.lunchPlansCreated,_that.familiesPlanningLunches,_that.newFamilies,_that.newFamiliesInvitingAnAdult,_that.isInviteCohortComplete,_that.computedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String week, @CalendarDateConverter()  CalendarDate weekStart,  int activeFamilies,  int familiesSeen,  int lunchPlansCreated,  int familiesPlanningLunches,  int newFamilies,  int newFamiliesInvitingAnAdult,  bool isInviteCohortComplete, @NullableTimestampConverter()  DateTime? computedAt)?  $default,) {final _that = this;
switch (_that) {
case _WeeklyNumbers() when $default != null:
return $default(_that.week,_that.weekStart,_that.activeFamilies,_that.familiesSeen,_that.lunchPlansCreated,_that.familiesPlanningLunches,_that.newFamilies,_that.newFamiliesInvitingAnAdult,_that.isInviteCohortComplete,_that.computedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WeeklyNumbers extends WeeklyNumbers {
  const _WeeklyNumbers({required this.week, @CalendarDateConverter() required this.weekStart, this.activeFamilies = 0, this.familiesSeen = 0, this.lunchPlansCreated = 0, this.familiesPlanningLunches = 0, this.newFamilies = 0, this.newFamiliesInvitingAnAdult = 0, this.isInviteCohortComplete = false, @NullableTimestampConverter() this.computedAt}): super._();
  factory _WeeklyNumbers.fromJson(Map<String, dynamic> json) => _$WeeklyNumbersFromJson(json);

/// The ISO week, `YYYY-Www` — also the document id.
@override final  String week;
/// The Monday the week starts on.
@override@CalendarDateConverter() final  CalendarDate weekStart;
/// The north star: families where two or more people used NestPrep.
@override@JsonKey() final  int activeFamilies;
/// Families where anybody did — what [activeFamilies] is read against.
@override@JsonKey() final  int familiesSeen;
@override@JsonKey() final  int lunchPlansCreated;
@override@JsonKey() final  int familiesPlanningLunches;
/// Families created this week: the invite cohort.
@override@JsonKey() final  int newFamilies;
@override@JsonKey() final  int newFamiliesInvitingAnAdult;
/// False until every family in the cohort has had its first seven days.
@override@JsonKey() final  bool isInviteCohortComplete;
@override@NullableTimestampConverter() final  DateTime? computedAt;

/// Create a copy of WeeklyNumbers
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WeeklyNumbersCopyWith<_WeeklyNumbers> get copyWith => __$WeeklyNumbersCopyWithImpl<_WeeklyNumbers>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WeeklyNumbersToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _WeeklyNumbers&&(identical(other.week, week) || other.week == week)&&(identical(other.weekStart, weekStart) || other.weekStart == weekStart)&&(identical(other.activeFamilies, activeFamilies) || other.activeFamilies == activeFamilies)&&(identical(other.familiesSeen, familiesSeen) || other.familiesSeen == familiesSeen)&&(identical(other.lunchPlansCreated, lunchPlansCreated) || other.lunchPlansCreated == lunchPlansCreated)&&(identical(other.familiesPlanningLunches, familiesPlanningLunches) || other.familiesPlanningLunches == familiesPlanningLunches)&&(identical(other.newFamilies, newFamilies) || other.newFamilies == newFamilies)&&(identical(other.newFamiliesInvitingAnAdult, newFamiliesInvitingAnAdult) || other.newFamiliesInvitingAnAdult == newFamiliesInvitingAnAdult)&&(identical(other.isInviteCohortComplete, isInviteCohortComplete) || other.isInviteCohortComplete == isInviteCohortComplete)&&(identical(other.computedAt, computedAt) || other.computedAt == computedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,week,weekStart,activeFamilies,familiesSeen,lunchPlansCreated,familiesPlanningLunches,newFamilies,newFamiliesInvitingAnAdult,isInviteCohortComplete,computedAt);
}

@override
String toString() {
    return 'WeeklyNumbers(week: $week, weekStart: $weekStart, activeFamilies: $activeFamilies, familiesSeen: $familiesSeen, lunchPlansCreated: $lunchPlansCreated, familiesPlanningLunches: $familiesPlanningLunches, newFamilies: $newFamilies, newFamiliesInvitingAnAdult: $newFamiliesInvitingAnAdult, isInviteCohortComplete: $isInviteCohortComplete, computedAt: $computedAt)';
}


}

/// @nodoc
abstract mixin class _$WeeklyNumbersCopyWith<$Res> implements $WeeklyNumbersCopyWith<$Res> {
  factory _$WeeklyNumbersCopyWith(_WeeklyNumbers value, $Res Function(_WeeklyNumbers) _then) = __$WeeklyNumbersCopyWithImpl;
@override @useResult
$Res call({
 String week,@CalendarDateConverter() CalendarDate weekStart, int activeFamilies, int familiesSeen, int lunchPlansCreated, int familiesPlanningLunches, int newFamilies, int newFamiliesInvitingAnAdult, bool isInviteCohortComplete,@NullableTimestampConverter() DateTime? computedAt
});




}
/// @nodoc
class __$WeeklyNumbersCopyWithImpl<$Res>
    implements _$WeeklyNumbersCopyWith<$Res> {
  __$WeeklyNumbersCopyWithImpl(this._self, this._then);

  final _WeeklyNumbers _self;
  final $Res Function(_WeeklyNumbers) _then;

/// Create a copy of WeeklyNumbers
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? week = null,Object? weekStart = null,Object? activeFamilies = null,Object? familiesSeen = null,Object? lunchPlansCreated = null,Object? familiesPlanningLunches = null,Object? newFamilies = null,Object? newFamiliesInvitingAnAdult = null,Object? isInviteCohortComplete = null,Object? computedAt = freezed,}) {
  return _then(_WeeklyNumbers(
week: null == week ? _self.week : week // ignore: cast_nullable_to_non_nullable
as String,weekStart: null == weekStart ? _self.weekStart : weekStart // ignore: cast_nullable_to_non_nullable
as CalendarDate,activeFamilies: null == activeFamilies ? _self.activeFamilies : activeFamilies // ignore: cast_nullable_to_non_nullable
as int,familiesSeen: null == familiesSeen ? _self.familiesSeen : familiesSeen // ignore: cast_nullable_to_non_nullable
as int,lunchPlansCreated: null == lunchPlansCreated ? _self.lunchPlansCreated : lunchPlansCreated // ignore: cast_nullable_to_non_nullable
as int,familiesPlanningLunches: null == familiesPlanningLunches ? _self.familiesPlanningLunches : familiesPlanningLunches // ignore: cast_nullable_to_non_nullable
as int,newFamilies: null == newFamilies ? _self.newFamilies : newFamilies // ignore: cast_nullable_to_non_nullable
as int,newFamiliesInvitingAnAdult: null == newFamiliesInvitingAnAdult ? _self.newFamiliesInvitingAnAdult : newFamiliesInvitingAnAdult // ignore: cast_nullable_to_non_nullable
as int,isInviteCohortComplete: null == isInviteCohortComplete ? _self.isInviteCohortComplete : isInviteCohortComplete // ignore: cast_nullable_to_non_nullable
as bool,computedAt: freezed == computedAt ? _self.computedAt : computedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
