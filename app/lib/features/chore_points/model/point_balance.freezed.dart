// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'point_balance.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PointBalance {

/// The kid profile these stars belong to — also the document id.
@JsonKey(includeToJson: false) String get id; int get balance;/// Every star ever earned, net of chores unticked.
 int get earned;/// Every star spent on rewards, net of rewards declined.
 int get spent; int get streakDays; int get bestStreak;/// The last day stars landed, in the household's zone.
@NullableCalendarDateConverter() CalendarDate? get streakLastDay;@NullableTimestampConverter() DateTime? get updatedAt;
/// Create a copy of PointBalance
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PointBalanceCopyWith<PointBalance> get copyWith => _$PointBalanceCopyWithImpl<PointBalance>(this as PointBalance, _$identity);

  /// Serializes this PointBalance to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PointBalance;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PointBalance&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.balance, _this.balance) || other.balance == _this.balance)&&(identical(other.earned, _this.earned) || other.earned == _this.earned)&&(identical(other.spent, _this.spent) || other.spent == _this.spent)&&(identical(other.streakDays, _this.streakDays) || other.streakDays == _this.streakDays)&&(identical(other.bestStreak, _this.bestStreak) || other.bestStreak == _this.bestStreak)&&(identical(other.streakLastDay, _this.streakLastDay) || other.streakLastDay == _this.streakLastDay)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PointBalance;
  return Object.hash(runtimeType,_this.id,_this.balance,_this.earned,_this.spent,_this.streakDays,_this.bestStreak,_this.streakLastDay,_this.updatedAt);
}

@override
String toString() {
  final _this = this as PointBalance;
  return 'PointBalance(id: ${_this.id}, balance: ${_this.balance}, earned: ${_this.earned}, spent: ${_this.spent}, streakDays: ${_this.streakDays}, bestStreak: ${_this.bestStreak}, streakLastDay: ${_this.streakLastDay}, updatedAt: ${_this.updatedAt})';
}


}

/// @nodoc
abstract mixin class $PointBalanceCopyWith<$Res>  {
  factory $PointBalanceCopyWith(PointBalance value, $Res Function(PointBalance) _then) = _$PointBalanceCopyWithImpl;
@useResult
$Res call({
@JsonKey(includeToJson: false) String id, int balance, int earned, int spent, int streakDays, int bestStreak,@NullableCalendarDateConverter() CalendarDate? streakLastDay,@NullableTimestampConverter() DateTime? updatedAt
});




}
/// @nodoc
class _$PointBalanceCopyWithImpl<$Res>
    implements $PointBalanceCopyWith<$Res> {
  _$PointBalanceCopyWithImpl(this._self, this._then);

  final PointBalance _self;
  final $Res Function(PointBalance) _then;

/// Create a copy of PointBalance
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? balance = null,Object? earned = null,Object? spent = null,Object? streakDays = null,Object? bestStreak = null,Object? streakLastDay = freezed,Object? updatedAt = freezed,}) {
  return _then(PointBalance(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,balance: null == balance ? _self.balance : balance // ignore: cast_nullable_to_non_nullable
as int,earned: null == earned ? _self.earned : earned // ignore: cast_nullable_to_non_nullable
as int,spent: null == spent ? _self.spent : spent // ignore: cast_nullable_to_non_nullable
as int,streakDays: null == streakDays ? _self.streakDays : streakDays // ignore: cast_nullable_to_non_nullable
as int,bestStreak: null == bestStreak ? _self.bestStreak : bestStreak // ignore: cast_nullable_to_non_nullable
as int,streakLastDay: freezed == streakLastDay ? _self.streakLastDay : streakLastDay // ignore: cast_nullable_to_non_nullable
as CalendarDate?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [PointBalance].
extension PointBalancePatterns on PointBalance {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PointBalance value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PointBalance() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PointBalance value)  $default,){
final _that = this;
switch (_that) {
case _PointBalance():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PointBalance value)?  $default,){
final _that = this;
switch (_that) {
case _PointBalance() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  int balance,  int earned,  int spent,  int streakDays,  int bestStreak, @NullableCalendarDateConverter()  CalendarDate? streakLastDay, @NullableTimestampConverter()  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PointBalance() when $default != null:
return $default(_that.id,_that.balance,_that.earned,_that.spent,_that.streakDays,_that.bestStreak,_that.streakLastDay,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  int balance,  int earned,  int spent,  int streakDays,  int bestStreak, @NullableCalendarDateConverter()  CalendarDate? streakLastDay, @NullableTimestampConverter()  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _PointBalance():
return $default(_that.id,_that.balance,_that.earned,_that.spent,_that.streakDays,_that.bestStreak,_that.streakLastDay,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(includeToJson: false)  String id,  int balance,  int earned,  int spent,  int streakDays,  int bestStreak, @NullableCalendarDateConverter()  CalendarDate? streakLastDay, @NullableTimestampConverter()  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _PointBalance() when $default != null:
return $default(_that.id,_that.balance,_that.earned,_that.spent,_that.streakDays,_that.bestStreak,_that.streakLastDay,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PointBalance extends PointBalance {
  const _PointBalance({@JsonKey(includeToJson: false) required this.id, this.balance = 0, this.earned = 0, this.spent = 0, this.streakDays = 0, this.bestStreak = 0, @NullableCalendarDateConverter() this.streakLastDay, @NullableTimestampConverter() this.updatedAt}): super._();
  factory _PointBalance.fromJson(Map<String, dynamic> json) => _$PointBalanceFromJson(json);

/// The kid profile these stars belong to — also the document id.
@override@JsonKey(includeToJson: false) final  String id;
@override@JsonKey() final  int balance;
/// Every star ever earned, net of chores unticked.
@override@JsonKey() final  int earned;
/// Every star spent on rewards, net of rewards declined.
@override@JsonKey() final  int spent;
@override@JsonKey() final  int streakDays;
@override@JsonKey() final  int bestStreak;
/// The last day stars landed, in the household's zone.
@override@NullableCalendarDateConverter() final  CalendarDate? streakLastDay;
@override@NullableTimestampConverter() final  DateTime? updatedAt;

/// Create a copy of PointBalance
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PointBalanceCopyWith<_PointBalance> get copyWith => __$PointBalanceCopyWithImpl<_PointBalance>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PointBalanceToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PointBalance&&(identical(other.id, id) || other.id == id)&&(identical(other.balance, balance) || other.balance == balance)&&(identical(other.earned, earned) || other.earned == earned)&&(identical(other.spent, spent) || other.spent == spent)&&(identical(other.streakDays, streakDays) || other.streakDays == streakDays)&&(identical(other.bestStreak, bestStreak) || other.bestStreak == bestStreak)&&(identical(other.streakLastDay, streakLastDay) || other.streakLastDay == streakLastDay)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,balance,earned,spent,streakDays,bestStreak,streakLastDay,updatedAt);
}

@override
String toString() {
    return 'PointBalance(id: $id, balance: $balance, earned: $earned, spent: $spent, streakDays: $streakDays, bestStreak: $bestStreak, streakLastDay: $streakLastDay, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$PointBalanceCopyWith<$Res> implements $PointBalanceCopyWith<$Res> {
  factory _$PointBalanceCopyWith(_PointBalance value, $Res Function(_PointBalance) _then) = __$PointBalanceCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(includeToJson: false) String id, int balance, int earned, int spent, int streakDays, int bestStreak,@NullableCalendarDateConverter() CalendarDate? streakLastDay,@NullableTimestampConverter() DateTime? updatedAt
});




}
/// @nodoc
class __$PointBalanceCopyWithImpl<$Res>
    implements _$PointBalanceCopyWith<$Res> {
  __$PointBalanceCopyWithImpl(this._self, this._then);

  final _PointBalance _self;
  final $Res Function(_PointBalance) _then;

/// Create a copy of PointBalance
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? balance = null,Object? earned = null,Object? spent = null,Object? streakDays = null,Object? bestStreak = null,Object? streakLastDay = freezed,Object? updatedAt = freezed,}) {
  return _then(_PointBalance(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,balance: null == balance ? _self.balance : balance // ignore: cast_nullable_to_non_nullable
as int,earned: null == earned ? _self.earned : earned // ignore: cast_nullable_to_non_nullable
as int,spent: null == spent ? _self.spent : spent // ignore: cast_nullable_to_non_nullable
as int,streakDays: null == streakDays ? _self.streakDays : streakDays // ignore: cast_nullable_to_non_nullable
as int,bestStreak: null == bestStreak ? _self.bestStreak : bestStreak // ignore: cast_nullable_to_non_nullable
as int,streakLastDay: freezed == streakLastDay ? _self.streakLastDay : streakLastDay // ignore: cast_nullable_to_non_nullable
as CalendarDate?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
