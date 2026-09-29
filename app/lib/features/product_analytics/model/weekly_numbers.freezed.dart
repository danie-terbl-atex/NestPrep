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
 bool get isInviteCohortComplete;/// Families shown the paywall at all this week (product-analytics
/// ADR-0002) — what conversion is read against.
 int get paywallFamilies;/// The same by trigger — the server's `CONVERSION_TRIGGERS`, which are
/// `PremiumFeature`'s names. A family counts once for each it met.
 Map<String, int> get paywallFamiliesByTrigger; int get premiumConversions; Map<String, int> get premiumConversionsByTrigger;/// Give a month, get a month (subscriptions ADR-0002): codes entered,
/// referrals that became a family, and the free months that gave.
 int get referralsRedeemed; int get referralsQualified; int get referralMonthsGiven;@NullableTimestampConverter() DateTime? get computedAt;
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WeeklyNumbers&&(identical(other.week, _this.week) || other.week == _this.week)&&(identical(other.weekStart, _this.weekStart) || other.weekStart == _this.weekStart)&&(identical(other.activeFamilies, _this.activeFamilies) || other.activeFamilies == _this.activeFamilies)&&(identical(other.familiesSeen, _this.familiesSeen) || other.familiesSeen == _this.familiesSeen)&&(identical(other.lunchPlansCreated, _this.lunchPlansCreated) || other.lunchPlansCreated == _this.lunchPlansCreated)&&(identical(other.familiesPlanningLunches, _this.familiesPlanningLunches) || other.familiesPlanningLunches == _this.familiesPlanningLunches)&&(identical(other.newFamilies, _this.newFamilies) || other.newFamilies == _this.newFamilies)&&(identical(other.newFamiliesInvitingAnAdult, _this.newFamiliesInvitingAnAdult) || other.newFamiliesInvitingAnAdult == _this.newFamiliesInvitingAnAdult)&&(identical(other.isInviteCohortComplete, _this.isInviteCohortComplete) || other.isInviteCohortComplete == _this.isInviteCohortComplete)&&(identical(other.paywallFamilies, _this.paywallFamilies) || other.paywallFamilies == _this.paywallFamilies)&&const DeepCollectionEquality().equals(other.paywallFamiliesByTrigger, _this.paywallFamiliesByTrigger)&&(identical(other.premiumConversions, _this.premiumConversions) || other.premiumConversions == _this.premiumConversions)&&const DeepCollectionEquality().equals(other.premiumConversionsByTrigger, _this.premiumConversionsByTrigger)&&(identical(other.referralsRedeemed, _this.referralsRedeemed) || other.referralsRedeemed == _this.referralsRedeemed)&&(identical(other.referralsQualified, _this.referralsQualified) || other.referralsQualified == _this.referralsQualified)&&(identical(other.referralMonthsGiven, _this.referralMonthsGiven) || other.referralMonthsGiven == _this.referralMonthsGiven)&&(identical(other.computedAt, _this.computedAt) || other.computedAt == _this.computedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as WeeklyNumbers;
  return Object.hash(runtimeType,_this.week,_this.weekStart,_this.activeFamilies,_this.familiesSeen,_this.lunchPlansCreated,_this.familiesPlanningLunches,_this.newFamilies,_this.newFamiliesInvitingAnAdult,_this.isInviteCohortComplete,_this.paywallFamilies,const DeepCollectionEquality().hash(_this.paywallFamiliesByTrigger),_this.premiumConversions,const DeepCollectionEquality().hash(_this.premiumConversionsByTrigger),_this.referralsRedeemed,_this.referralsQualified,_this.referralMonthsGiven,_this.computedAt);
}

@override
String toString() {
  final _this = this as WeeklyNumbers;
  return 'WeeklyNumbers(week: ${_this.week}, weekStart: ${_this.weekStart}, activeFamilies: ${_this.activeFamilies}, familiesSeen: ${_this.familiesSeen}, lunchPlansCreated: ${_this.lunchPlansCreated}, familiesPlanningLunches: ${_this.familiesPlanningLunches}, newFamilies: ${_this.newFamilies}, newFamiliesInvitingAnAdult: ${_this.newFamiliesInvitingAnAdult}, isInviteCohortComplete: ${_this.isInviteCohortComplete}, paywallFamilies: ${_this.paywallFamilies}, paywallFamiliesByTrigger: ${_this.paywallFamiliesByTrigger}, premiumConversions: ${_this.premiumConversions}, premiumConversionsByTrigger: ${_this.premiumConversionsByTrigger}, referralsRedeemed: ${_this.referralsRedeemed}, referralsQualified: ${_this.referralsQualified}, referralMonthsGiven: ${_this.referralMonthsGiven}, computedAt: ${_this.computedAt})';
}


}

/// @nodoc
abstract mixin class $WeeklyNumbersCopyWith<$Res>  {
  factory $WeeklyNumbersCopyWith(WeeklyNumbers value, $Res Function(WeeklyNumbers) _then) = _$WeeklyNumbersCopyWithImpl;
@useResult
$Res call({
 String week,@CalendarDateConverter() CalendarDate weekStart, int activeFamilies, int familiesSeen, int lunchPlansCreated, int familiesPlanningLunches, int newFamilies, int newFamiliesInvitingAnAdult, bool isInviteCohortComplete, int paywallFamilies, Map<String, int> paywallFamiliesByTrigger, int premiumConversions, Map<String, int> premiumConversionsByTrigger, int referralsRedeemed, int referralsQualified, int referralMonthsGiven,@NullableTimestampConverter() DateTime? computedAt
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
@pragma('vm:prefer-inline') @override $Res call({Object? week = null,Object? weekStart = null,Object? activeFamilies = null,Object? familiesSeen = null,Object? lunchPlansCreated = null,Object? familiesPlanningLunches = null,Object? newFamilies = null,Object? newFamiliesInvitingAnAdult = null,Object? isInviteCohortComplete = null,Object? paywallFamilies = null,Object? paywallFamiliesByTrigger = null,Object? premiumConversions = null,Object? premiumConversionsByTrigger = null,Object? referralsRedeemed = null,Object? referralsQualified = null,Object? referralMonthsGiven = null,Object? computedAt = freezed,}) {
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
as bool,paywallFamilies: null == paywallFamilies ? _self.paywallFamilies : paywallFamilies // ignore: cast_nullable_to_non_nullable
as int,paywallFamiliesByTrigger: null == paywallFamiliesByTrigger ? _self.paywallFamiliesByTrigger : paywallFamiliesByTrigger // ignore: cast_nullable_to_non_nullable
as Map<String, int>,premiumConversions: null == premiumConversions ? _self.premiumConversions : premiumConversions // ignore: cast_nullable_to_non_nullable
as int,premiumConversionsByTrigger: null == premiumConversionsByTrigger ? _self.premiumConversionsByTrigger : premiumConversionsByTrigger // ignore: cast_nullable_to_non_nullable
as Map<String, int>,referralsRedeemed: null == referralsRedeemed ? _self.referralsRedeemed : referralsRedeemed // ignore: cast_nullable_to_non_nullable
as int,referralsQualified: null == referralsQualified ? _self.referralsQualified : referralsQualified // ignore: cast_nullable_to_non_nullable
as int,referralMonthsGiven: null == referralMonthsGiven ? _self.referralMonthsGiven : referralMonthsGiven // ignore: cast_nullable_to_non_nullable
as int,computedAt: freezed == computedAt ? _self.computedAt : computedAt // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String week, @CalendarDateConverter()  CalendarDate weekStart,  int activeFamilies,  int familiesSeen,  int lunchPlansCreated,  int familiesPlanningLunches,  int newFamilies,  int newFamiliesInvitingAnAdult,  bool isInviteCohortComplete,  int paywallFamilies,  Map<String, int> paywallFamiliesByTrigger,  int premiumConversions,  Map<String, int> premiumConversionsByTrigger,  int referralsRedeemed,  int referralsQualified,  int referralMonthsGiven, @NullableTimestampConverter()  DateTime? computedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WeeklyNumbers() when $default != null:
return $default(_that.week,_that.weekStart,_that.activeFamilies,_that.familiesSeen,_that.lunchPlansCreated,_that.familiesPlanningLunches,_that.newFamilies,_that.newFamiliesInvitingAnAdult,_that.isInviteCohortComplete,_that.paywallFamilies,_that.paywallFamiliesByTrigger,_that.premiumConversions,_that.premiumConversionsByTrigger,_that.referralsRedeemed,_that.referralsQualified,_that.referralMonthsGiven,_that.computedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String week, @CalendarDateConverter()  CalendarDate weekStart,  int activeFamilies,  int familiesSeen,  int lunchPlansCreated,  int familiesPlanningLunches,  int newFamilies,  int newFamiliesInvitingAnAdult,  bool isInviteCohortComplete,  int paywallFamilies,  Map<String, int> paywallFamiliesByTrigger,  int premiumConversions,  Map<String, int> premiumConversionsByTrigger,  int referralsRedeemed,  int referralsQualified,  int referralMonthsGiven, @NullableTimestampConverter()  DateTime? computedAt)  $default,) {final _that = this;
switch (_that) {
case _WeeklyNumbers():
return $default(_that.week,_that.weekStart,_that.activeFamilies,_that.familiesSeen,_that.lunchPlansCreated,_that.familiesPlanningLunches,_that.newFamilies,_that.newFamiliesInvitingAnAdult,_that.isInviteCohortComplete,_that.paywallFamilies,_that.paywallFamiliesByTrigger,_that.premiumConversions,_that.premiumConversionsByTrigger,_that.referralsRedeemed,_that.referralsQualified,_that.referralMonthsGiven,_that.computedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String week, @CalendarDateConverter()  CalendarDate weekStart,  int activeFamilies,  int familiesSeen,  int lunchPlansCreated,  int familiesPlanningLunches,  int newFamilies,  int newFamiliesInvitingAnAdult,  bool isInviteCohortComplete,  int paywallFamilies,  Map<String, int> paywallFamiliesByTrigger,  int premiumConversions,  Map<String, int> premiumConversionsByTrigger,  int referralsRedeemed,  int referralsQualified,  int referralMonthsGiven, @NullableTimestampConverter()  DateTime? computedAt)?  $default,) {final _that = this;
switch (_that) {
case _WeeklyNumbers() when $default != null:
return $default(_that.week,_that.weekStart,_that.activeFamilies,_that.familiesSeen,_that.lunchPlansCreated,_that.familiesPlanningLunches,_that.newFamilies,_that.newFamiliesInvitingAnAdult,_that.isInviteCohortComplete,_that.paywallFamilies,_that.paywallFamiliesByTrigger,_that.premiumConversions,_that.premiumConversionsByTrigger,_that.referralsRedeemed,_that.referralsQualified,_that.referralMonthsGiven,_that.computedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WeeklyNumbers extends WeeklyNumbers {
  const _WeeklyNumbers({required this.week, @CalendarDateConverter() required this.weekStart, this.activeFamilies = 0, this.familiesSeen = 0, this.lunchPlansCreated = 0, this.familiesPlanningLunches = 0, this.newFamilies = 0, this.newFamiliesInvitingAnAdult = 0, this.isInviteCohortComplete = false, this.paywallFamilies = 0,  Map<String, int> paywallFamiliesByTrigger = const <String, int>{}, this.premiumConversions = 0,  Map<String, int> premiumConversionsByTrigger = const <String, int>{}, this.referralsRedeemed = 0, this.referralsQualified = 0, this.referralMonthsGiven = 0, @NullableTimestampConverter() this.computedAt}): _paywallFamiliesByTrigger = paywallFamiliesByTrigger,_premiumConversionsByTrigger = premiumConversionsByTrigger,super._();
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
/// Families shown the paywall at all this week (product-analytics
/// ADR-0002) — what conversion is read against.
@override@JsonKey() final  int paywallFamilies;
/// The same by trigger — the server's `CONVERSION_TRIGGERS`, which are
/// `PremiumFeature`'s names. A family counts once for each it met.
 final  Map<String, int> _paywallFamiliesByTrigger;
/// The same by trigger — the server's `CONVERSION_TRIGGERS`, which are
/// `PremiumFeature`'s names. A family counts once for each it met.
@override@JsonKey() Map<String, int> get paywallFamiliesByTrigger {
  if (_paywallFamiliesByTrigger is EqualUnmodifiableMapView) return _paywallFamiliesByTrigger;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_paywallFamiliesByTrigger);
}

@override@JsonKey() final  int premiumConversions;
 final  Map<String, int> _premiumConversionsByTrigger;
@override@JsonKey() Map<String, int> get premiumConversionsByTrigger {
  if (_premiumConversionsByTrigger is EqualUnmodifiableMapView) return _premiumConversionsByTrigger;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_premiumConversionsByTrigger);
}

/// Give a month, get a month (subscriptions ADR-0002): codes entered,
/// referrals that became a family, and the free months that gave.
@override@JsonKey() final  int referralsRedeemed;
@override@JsonKey() final  int referralsQualified;
@override@JsonKey() final  int referralMonthsGiven;
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
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _WeeklyNumbers&&(identical(other.week, week) || other.week == week)&&(identical(other.weekStart, weekStart) || other.weekStart == weekStart)&&(identical(other.activeFamilies, activeFamilies) || other.activeFamilies == activeFamilies)&&(identical(other.familiesSeen, familiesSeen) || other.familiesSeen == familiesSeen)&&(identical(other.lunchPlansCreated, lunchPlansCreated) || other.lunchPlansCreated == lunchPlansCreated)&&(identical(other.familiesPlanningLunches, familiesPlanningLunches) || other.familiesPlanningLunches == familiesPlanningLunches)&&(identical(other.newFamilies, newFamilies) || other.newFamilies == newFamilies)&&(identical(other.newFamiliesInvitingAnAdult, newFamiliesInvitingAnAdult) || other.newFamiliesInvitingAnAdult == newFamiliesInvitingAnAdult)&&(identical(other.isInviteCohortComplete, isInviteCohortComplete) || other.isInviteCohortComplete == isInviteCohortComplete)&&(identical(other.paywallFamilies, paywallFamilies) || other.paywallFamilies == paywallFamilies)&&const DeepCollectionEquality().equals(other.paywallFamiliesByTrigger, _paywallFamiliesByTrigger)&&(identical(other.premiumConversions, premiumConversions) || other.premiumConversions == premiumConversions)&&const DeepCollectionEquality().equals(other.premiumConversionsByTrigger, _premiumConversionsByTrigger)&&(identical(other.referralsRedeemed, referralsRedeemed) || other.referralsRedeemed == referralsRedeemed)&&(identical(other.referralsQualified, referralsQualified) || other.referralsQualified == referralsQualified)&&(identical(other.referralMonthsGiven, referralMonthsGiven) || other.referralMonthsGiven == referralMonthsGiven)&&(identical(other.computedAt, computedAt) || other.computedAt == computedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,week,weekStart,activeFamilies,familiesSeen,lunchPlansCreated,familiesPlanningLunches,newFamilies,newFamiliesInvitingAnAdult,isInviteCohortComplete,paywallFamilies,const DeepCollectionEquality().hash(_paywallFamiliesByTrigger),premiumConversions,const DeepCollectionEquality().hash(_premiumConversionsByTrigger),referralsRedeemed,referralsQualified,referralMonthsGiven,computedAt);
}

@override
String toString() {
    return 'WeeklyNumbers(week: $week, weekStart: $weekStart, activeFamilies: $activeFamilies, familiesSeen: $familiesSeen, lunchPlansCreated: $lunchPlansCreated, familiesPlanningLunches: $familiesPlanningLunches, newFamilies: $newFamilies, newFamiliesInvitingAnAdult: $newFamiliesInvitingAnAdult, isInviteCohortComplete: $isInviteCohortComplete, paywallFamilies: $paywallFamilies, paywallFamiliesByTrigger: $paywallFamiliesByTrigger, premiumConversions: $premiumConversions, premiumConversionsByTrigger: $premiumConversionsByTrigger, referralsRedeemed: $referralsRedeemed, referralsQualified: $referralsQualified, referralMonthsGiven: $referralMonthsGiven, computedAt: $computedAt)';
}


}

/// @nodoc
abstract mixin class _$WeeklyNumbersCopyWith<$Res> implements $WeeklyNumbersCopyWith<$Res> {
  factory _$WeeklyNumbersCopyWith(_WeeklyNumbers value, $Res Function(_WeeklyNumbers) _then) = __$WeeklyNumbersCopyWithImpl;
@override @useResult
$Res call({
 String week,@CalendarDateConverter() CalendarDate weekStart, int activeFamilies, int familiesSeen, int lunchPlansCreated, int familiesPlanningLunches, int newFamilies, int newFamiliesInvitingAnAdult, bool isInviteCohortComplete, int paywallFamilies, Map<String, int> paywallFamiliesByTrigger, int premiumConversions, Map<String, int> premiumConversionsByTrigger, int referralsRedeemed, int referralsQualified, int referralMonthsGiven,@NullableTimestampConverter() DateTime? computedAt
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
@override @pragma('vm:prefer-inline') $Res call({Object? week = null,Object? weekStart = null,Object? activeFamilies = null,Object? familiesSeen = null,Object? lunchPlansCreated = null,Object? familiesPlanningLunches = null,Object? newFamilies = null,Object? newFamiliesInvitingAnAdult = null,Object? isInviteCohortComplete = null,Object? paywallFamilies = null,Object? paywallFamiliesByTrigger = null,Object? premiumConversions = null,Object? premiumConversionsByTrigger = null,Object? referralsRedeemed = null,Object? referralsQualified = null,Object? referralMonthsGiven = null,Object? computedAt = freezed,}) {
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
as bool,paywallFamilies: null == paywallFamilies ? _self.paywallFamilies : paywallFamilies // ignore: cast_nullable_to_non_nullable
as int,paywallFamiliesByTrigger: null == paywallFamiliesByTrigger ? _self._paywallFamiliesByTrigger : paywallFamiliesByTrigger // ignore: cast_nullable_to_non_nullable
as Map<String, int>,premiumConversions: null == premiumConversions ? _self.premiumConversions : premiumConversions // ignore: cast_nullable_to_non_nullable
as int,premiumConversionsByTrigger: null == premiumConversionsByTrigger ? _self._premiumConversionsByTrigger : premiumConversionsByTrigger // ignore: cast_nullable_to_non_nullable
as Map<String, int>,referralsRedeemed: null == referralsRedeemed ? _self.referralsRedeemed : referralsRedeemed // ignore: cast_nullable_to_non_nullable
as int,referralsQualified: null == referralsQualified ? _self.referralsQualified : referralsQualified // ignore: cast_nullable_to_non_nullable
as int,referralMonthsGiven: null == referralMonthsGiven ? _self.referralMonthsGiven : referralMonthsGiven // ignore: cast_nullable_to_non_nullable
as int,computedAt: freezed == computedAt ? _self.computedAt : computedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
