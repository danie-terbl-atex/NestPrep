// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'lunch_plan.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LunchPlan {

@JsonKey(includeToJson: false) String get id; String get childId;/// `YYYY-Www` — also the tail of the document id.
 String get week;/// The Monday, `YYYY-MM-DD`, which the household's listener orders and
/// bounds by.
 String get weekStart; Map<String, LunchPick> get slots;/// Weekday (`'1'`–`'5'`) → what came home that day.
 Map<String, LunchFeedback> get feedback;
/// Create a copy of LunchPlan
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LunchPlanCopyWith<LunchPlan> get copyWith => _$LunchPlanCopyWithImpl<LunchPlan>(this as LunchPlan, _$identity);

  /// Serializes this LunchPlan to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as LunchPlan;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LunchPlan&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.childId, _this.childId) || other.childId == _this.childId)&&(identical(other.week, _this.week) || other.week == _this.week)&&(identical(other.weekStart, _this.weekStart) || other.weekStart == _this.weekStart)&&const DeepCollectionEquality().equals(other.slots, _this.slots)&&const DeepCollectionEquality().equals(other.feedback, _this.feedback));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as LunchPlan;
  return Object.hash(runtimeType,_this.id,_this.childId,_this.week,_this.weekStart,const DeepCollectionEquality().hash(_this.slots),const DeepCollectionEquality().hash(_this.feedback));
}

@override
String toString() {
  final _this = this as LunchPlan;
  return 'LunchPlan(id: ${_this.id}, childId: ${_this.childId}, week: ${_this.week}, weekStart: ${_this.weekStart}, slots: ${_this.slots}, feedback: ${_this.feedback})';
}


}

/// @nodoc
abstract mixin class $LunchPlanCopyWith<$Res>  {
  factory $LunchPlanCopyWith(LunchPlan value, $Res Function(LunchPlan) _then) = _$LunchPlanCopyWithImpl;
@useResult
$Res call({
@JsonKey(includeToJson: false) String id, String childId, String week, String weekStart, Map<String, LunchPick> slots, Map<String, LunchFeedback> feedback
});




}
/// @nodoc
class _$LunchPlanCopyWithImpl<$Res>
    implements $LunchPlanCopyWith<$Res> {
  _$LunchPlanCopyWithImpl(this._self, this._then);

  final LunchPlan _self;
  final $Res Function(LunchPlan) _then;

/// Create a copy of LunchPlan
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? childId = null,Object? week = null,Object? weekStart = null,Object? slots = null,Object? feedback = null,}) {
  return _then(LunchPlan(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,childId: null == childId ? _self.childId : childId // ignore: cast_nullable_to_non_nullable
as String,week: null == week ? _self.week : week // ignore: cast_nullable_to_non_nullable
as String,weekStart: null == weekStart ? _self.weekStart : weekStart // ignore: cast_nullable_to_non_nullable
as String,slots: null == slots ? _self.slots : slots // ignore: cast_nullable_to_non_nullable
as Map<String, LunchPick>,feedback: null == feedback ? _self.feedback : feedback // ignore: cast_nullable_to_non_nullable
as Map<String, LunchFeedback>,
  ));
}

}


/// Adds pattern-matching-related methods to [LunchPlan].
extension LunchPlanPatterns on LunchPlan {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LunchPlan value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LunchPlan() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LunchPlan value)  $default,){
final _that = this;
switch (_that) {
case _LunchPlan():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LunchPlan value)?  $default,){
final _that = this;
switch (_that) {
case _LunchPlan() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  String childId,  String week,  String weekStart,  Map<String, LunchPick> slots,  Map<String, LunchFeedback> feedback)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LunchPlan() when $default != null:
return $default(_that.id,_that.childId,_that.week,_that.weekStart,_that.slots,_that.feedback);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  String childId,  String week,  String weekStart,  Map<String, LunchPick> slots,  Map<String, LunchFeedback> feedback)  $default,) {final _that = this;
switch (_that) {
case _LunchPlan():
return $default(_that.id,_that.childId,_that.week,_that.weekStart,_that.slots,_that.feedback);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(includeToJson: false)  String id,  String childId,  String week,  String weekStart,  Map<String, LunchPick> slots,  Map<String, LunchFeedback> feedback)?  $default,) {final _that = this;
switch (_that) {
case _LunchPlan() when $default != null:
return $default(_that.id,_that.childId,_that.week,_that.weekStart,_that.slots,_that.feedback);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LunchPlan extends LunchPlan {
  const _LunchPlan({@JsonKey(includeToJson: false) required this.id, required this.childId, required this.week, required this.weekStart,  Map<String, LunchPick> slots = const <String, LunchPick>{},  Map<String, LunchFeedback> feedback = const <String, LunchFeedback>{}}): _slots = slots,_feedback = feedback,super._();
  factory _LunchPlan.fromJson(Map<String, dynamic> json) => _$LunchPlanFromJson(json);

@override@JsonKey(includeToJson: false) final  String id;
@override final  String childId;
/// `YYYY-Www` — also the tail of the document id.
@override final  String week;
/// The Monday, `YYYY-MM-DD`, which the household's listener orders and
/// bounds by.
@override final  String weekStart;
 final  Map<String, LunchPick> _slots;
@override@JsonKey() Map<String, LunchPick> get slots {
  if (_slots is EqualUnmodifiableMapView) return _slots;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_slots);
}

/// Weekday (`'1'`–`'5'`) → what came home that day.
 final  Map<String, LunchFeedback> _feedback;
/// Weekday (`'1'`–`'5'`) → what came home that day.
@override@JsonKey() Map<String, LunchFeedback> get feedback {
  if (_feedback is EqualUnmodifiableMapView) return _feedback;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_feedback);
}


/// Create a copy of LunchPlan
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LunchPlanCopyWith<_LunchPlan> get copyWith => __$LunchPlanCopyWithImpl<_LunchPlan>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LunchPlanToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _LunchPlan&&(identical(other.id, id) || other.id == id)&&(identical(other.childId, childId) || other.childId == childId)&&(identical(other.week, week) || other.week == week)&&(identical(other.weekStart, weekStart) || other.weekStart == weekStart)&&const DeepCollectionEquality().equals(other.slots, _slots)&&const DeepCollectionEquality().equals(other.feedback, _feedback));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,childId,week,weekStart,const DeepCollectionEquality().hash(_slots),const DeepCollectionEquality().hash(_feedback));
}

@override
String toString() {
    return 'LunchPlan(id: $id, childId: $childId, week: $week, weekStart: $weekStart, slots: $slots, feedback: $feedback)';
}


}

/// @nodoc
abstract mixin class _$LunchPlanCopyWith<$Res> implements $LunchPlanCopyWith<$Res> {
  factory _$LunchPlanCopyWith(_LunchPlan value, $Res Function(_LunchPlan) _then) = __$LunchPlanCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(includeToJson: false) String id, String childId, String week, String weekStart, Map<String, LunchPick> slots, Map<String, LunchFeedback> feedback
});




}
/// @nodoc
class __$LunchPlanCopyWithImpl<$Res>
    implements _$LunchPlanCopyWith<$Res> {
  __$LunchPlanCopyWithImpl(this._self, this._then);

  final _LunchPlan _self;
  final $Res Function(_LunchPlan) _then;

/// Create a copy of LunchPlan
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? childId = null,Object? week = null,Object? weekStart = null,Object? slots = null,Object? feedback = null,}) {
  return _then(_LunchPlan(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,childId: null == childId ? _self.childId : childId // ignore: cast_nullable_to_non_nullable
as String,week: null == week ? _self.week : week // ignore: cast_nullable_to_non_nullable
as String,weekStart: null == weekStart ? _self.weekStart : weekStart // ignore: cast_nullable_to_non_nullable
as String,slots: null == slots ? _self._slots : slots // ignore: cast_nullable_to_non_nullable
as Map<String, LunchPick>,feedback: null == feedback ? _self._feedback : feedback // ignore: cast_nullable_to_non_nullable
as Map<String, LunchFeedback>,
  ));
}


}

// dart format on
