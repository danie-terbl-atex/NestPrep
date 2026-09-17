// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'recurrence_rule.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RecurrenceRule {

 RecurrenceFrequency get frequency;/// Every nth day, week or month. One means every one.
 int get interval;/// Which days a weekly rule lands on, as ISO weekdays. Empty means "the
/// same weekday the first occurrence fell on", which is what a member who
/// never opened the weekday picker meant.
 List<int> get weekdays;/// The last day an occurrence may fall on, inclusive. Null repeats forever.
@NullableCalendarDateConverter() CalendarDate? get until;
/// Create a copy of RecurrenceRule
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecurrenceRuleCopyWith<RecurrenceRule> get copyWith => _$RecurrenceRuleCopyWithImpl<RecurrenceRule>(this as RecurrenceRule, _$identity);

  /// Serializes this RecurrenceRule to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as RecurrenceRule;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecurrenceRule&&(identical(other.frequency, _this.frequency) || other.frequency == _this.frequency)&&(identical(other.interval, _this.interval) || other.interval == _this.interval)&&const DeepCollectionEquality().equals(other.weekdays, _this.weekdays)&&(identical(other.until, _this.until) || other.until == _this.until));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as RecurrenceRule;
  return Object.hash(runtimeType,_this.frequency,_this.interval,const DeepCollectionEquality().hash(_this.weekdays),_this.until);
}

@override
String toString() {
  final _this = this as RecurrenceRule;
  return 'RecurrenceRule(frequency: ${_this.frequency}, interval: ${_this.interval}, weekdays: ${_this.weekdays}, until: ${_this.until})';
}


}

/// @nodoc
abstract mixin class $RecurrenceRuleCopyWith<$Res>  {
  factory $RecurrenceRuleCopyWith(RecurrenceRule value, $Res Function(RecurrenceRule) _then) = _$RecurrenceRuleCopyWithImpl;
@useResult
$Res call({
 RecurrenceFrequency frequency, int interval, List<int> weekdays,@NullableCalendarDateConverter() CalendarDate? until
});




}
/// @nodoc
class _$RecurrenceRuleCopyWithImpl<$Res>
    implements $RecurrenceRuleCopyWith<$Res> {
  _$RecurrenceRuleCopyWithImpl(this._self, this._then);

  final RecurrenceRule _self;
  final $Res Function(RecurrenceRule) _then;

/// Create a copy of RecurrenceRule
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? frequency = null,Object? interval = null,Object? weekdays = null,Object? until = freezed,}) {
  return _then(RecurrenceRule(
frequency: null == frequency ? _self.frequency : frequency // ignore: cast_nullable_to_non_nullable
as RecurrenceFrequency,interval: null == interval ? _self.interval : interval // ignore: cast_nullable_to_non_nullable
as int,weekdays: null == weekdays ? _self.weekdays : weekdays // ignore: cast_nullable_to_non_nullable
as List<int>,until: freezed == until ? _self.until : until // ignore: cast_nullable_to_non_nullable
as CalendarDate?,
  ));
}

}


/// Adds pattern-matching-related methods to [RecurrenceRule].
extension RecurrenceRulePatterns on RecurrenceRule {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RecurrenceRule value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RecurrenceRule() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RecurrenceRule value)  $default,){
final _that = this;
switch (_that) {
case _RecurrenceRule():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RecurrenceRule value)?  $default,){
final _that = this;
switch (_that) {
case _RecurrenceRule() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( RecurrenceFrequency frequency,  int interval,  List<int> weekdays, @NullableCalendarDateConverter()  CalendarDate? until)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RecurrenceRule() when $default != null:
return $default(_that.frequency,_that.interval,_that.weekdays,_that.until);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( RecurrenceFrequency frequency,  int interval,  List<int> weekdays, @NullableCalendarDateConverter()  CalendarDate? until)  $default,) {final _that = this;
switch (_that) {
case _RecurrenceRule():
return $default(_that.frequency,_that.interval,_that.weekdays,_that.until);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( RecurrenceFrequency frequency,  int interval,  List<int> weekdays, @NullableCalendarDateConverter()  CalendarDate? until)?  $default,) {final _that = this;
switch (_that) {
case _RecurrenceRule() when $default != null:
return $default(_that.frequency,_that.interval,_that.weekdays,_that.until);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RecurrenceRule extends RecurrenceRule {
  const _RecurrenceRule({required this.frequency, this.interval = 1,  List<int> weekdays = const <int>[], @NullableCalendarDateConverter() this.until}): _weekdays = weekdays,super._();
  factory _RecurrenceRule.fromJson(Map<String, dynamic> json) => _$RecurrenceRuleFromJson(json);

@override final  RecurrenceFrequency frequency;
/// Every nth day, week or month. One means every one.
@override@JsonKey() final  int interval;
/// Which days a weekly rule lands on, as ISO weekdays. Empty means "the
/// same weekday the first occurrence fell on", which is what a member who
/// never opened the weekday picker meant.
 final  List<int> _weekdays;
/// Which days a weekly rule lands on, as ISO weekdays. Empty means "the
/// same weekday the first occurrence fell on", which is what a member who
/// never opened the weekday picker meant.
@override@JsonKey() List<int> get weekdays {
  if (_weekdays is EqualUnmodifiableListView) return _weekdays;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_weekdays);
}

/// The last day an occurrence may fall on, inclusive. Null repeats forever.
@override@NullableCalendarDateConverter() final  CalendarDate? until;

/// Create a copy of RecurrenceRule
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RecurrenceRuleCopyWith<_RecurrenceRule> get copyWith => __$RecurrenceRuleCopyWithImpl<_RecurrenceRule>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RecurrenceRuleToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RecurrenceRule&&(identical(other.frequency, frequency) || other.frequency == frequency)&&(identical(other.interval, interval) || other.interval == interval)&&const DeepCollectionEquality().equals(other.weekdays, _weekdays)&&(identical(other.until, until) || other.until == until));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,frequency,interval,const DeepCollectionEquality().hash(_weekdays),until);
}

@override
String toString() {
    return 'RecurrenceRule(frequency: $frequency, interval: $interval, weekdays: $weekdays, until: $until)';
}


}

/// @nodoc
abstract mixin class _$RecurrenceRuleCopyWith<$Res> implements $RecurrenceRuleCopyWith<$Res> {
  factory _$RecurrenceRuleCopyWith(_RecurrenceRule value, $Res Function(_RecurrenceRule) _then) = __$RecurrenceRuleCopyWithImpl;
@override @useResult
$Res call({
 RecurrenceFrequency frequency, int interval, List<int> weekdays,@NullableCalendarDateConverter() CalendarDate? until
});




}
/// @nodoc
class __$RecurrenceRuleCopyWithImpl<$Res>
    implements _$RecurrenceRuleCopyWith<$Res> {
  __$RecurrenceRuleCopyWithImpl(this._self, this._then);

  final _RecurrenceRule _self;
  final $Res Function(_RecurrenceRule) _then;

/// Create a copy of RecurrenceRule
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? frequency = null,Object? interval = null,Object? weekdays = null,Object? until = freezed,}) {
  return _then(_RecurrenceRule(
frequency: null == frequency ? _self.frequency : frequency // ignore: cast_nullable_to_non_nullable
as RecurrenceFrequency,interval: null == interval ? _self.interval : interval // ignore: cast_nullable_to_non_nullable
as int,weekdays: null == weekdays ? _self._weekdays : weekdays // ignore: cast_nullable_to_non_nullable
as List<int>,until: freezed == until ? _self.until : until // ignore: cast_nullable_to_non_nullable
as CalendarDate?,
  ));
}


}

// dart format on
