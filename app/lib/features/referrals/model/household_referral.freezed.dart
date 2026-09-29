// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'household_referral.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$HouseholdReferral {

/// Null until `ensureReferralCode` has made it.
 String? get code;/// The end of the household's first seven days, or null when its age is
/// unknown — then no code can be entered.
@NullableTimestampConverter() DateTime? get redeemBy;/// Whether this household has already entered somebody else's code.
 bool get hasRedeemed;/// The most referral months a household gets in a year — the server's
/// rule, said by the server.
 int get yearlyRewardCap;
/// Create a copy of HouseholdReferral
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HouseholdReferralCopyWith<HouseholdReferral> get copyWith => _$HouseholdReferralCopyWithImpl<HouseholdReferral>(this as HouseholdReferral, _$identity);

  /// Serializes this HouseholdReferral to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as HouseholdReferral;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HouseholdReferral&&(identical(other.code, _this.code) || other.code == _this.code)&&(identical(other.redeemBy, _this.redeemBy) || other.redeemBy == _this.redeemBy)&&(identical(other.hasRedeemed, _this.hasRedeemed) || other.hasRedeemed == _this.hasRedeemed)&&(identical(other.yearlyRewardCap, _this.yearlyRewardCap) || other.yearlyRewardCap == _this.yearlyRewardCap));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as HouseholdReferral;
  return Object.hash(runtimeType,_this.code,_this.redeemBy,_this.hasRedeemed,_this.yearlyRewardCap);
}

@override
String toString() {
  final _this = this as HouseholdReferral;
  return 'HouseholdReferral(code: ${_this.code}, redeemBy: ${_this.redeemBy}, hasRedeemed: ${_this.hasRedeemed}, yearlyRewardCap: ${_this.yearlyRewardCap})';
}


}

/// @nodoc
abstract mixin class $HouseholdReferralCopyWith<$Res>  {
  factory $HouseholdReferralCopyWith(HouseholdReferral value, $Res Function(HouseholdReferral) _then) = _$HouseholdReferralCopyWithImpl;
@useResult
$Res call({
 String? code,@NullableTimestampConverter() DateTime? redeemBy, bool hasRedeemed, int yearlyRewardCap
});




}
/// @nodoc
class _$HouseholdReferralCopyWithImpl<$Res>
    implements $HouseholdReferralCopyWith<$Res> {
  _$HouseholdReferralCopyWithImpl(this._self, this._then);

  final HouseholdReferral _self;
  final $Res Function(HouseholdReferral) _then;

/// Create a copy of HouseholdReferral
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = freezed,Object? redeemBy = freezed,Object? hasRedeemed = null,Object? yearlyRewardCap = null,}) {
  return _then(HouseholdReferral(
code: freezed == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String?,redeemBy: freezed == redeemBy ? _self.redeemBy : redeemBy // ignore: cast_nullable_to_non_nullable
as DateTime?,hasRedeemed: null == hasRedeemed ? _self.hasRedeemed : hasRedeemed // ignore: cast_nullable_to_non_nullable
as bool,yearlyRewardCap: null == yearlyRewardCap ? _self.yearlyRewardCap : yearlyRewardCap // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [HouseholdReferral].
extension HouseholdReferralPatterns on HouseholdReferral {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HouseholdReferral value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HouseholdReferral() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HouseholdReferral value)  $default,){
final _that = this;
switch (_that) {
case _HouseholdReferral():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HouseholdReferral value)?  $default,){
final _that = this;
switch (_that) {
case _HouseholdReferral() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? code, @NullableTimestampConverter()  DateTime? redeemBy,  bool hasRedeemed,  int yearlyRewardCap)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HouseholdReferral() when $default != null:
return $default(_that.code,_that.redeemBy,_that.hasRedeemed,_that.yearlyRewardCap);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? code, @NullableTimestampConverter()  DateTime? redeemBy,  bool hasRedeemed,  int yearlyRewardCap)  $default,) {final _that = this;
switch (_that) {
case _HouseholdReferral():
return $default(_that.code,_that.redeemBy,_that.hasRedeemed,_that.yearlyRewardCap);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? code, @NullableTimestampConverter()  DateTime? redeemBy,  bool hasRedeemed,  int yearlyRewardCap)?  $default,) {final _that = this;
switch (_that) {
case _HouseholdReferral() when $default != null:
return $default(_that.code,_that.redeemBy,_that.hasRedeemed,_that.yearlyRewardCap);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HouseholdReferral extends HouseholdReferral {
  const _HouseholdReferral({this.code, @NullableTimestampConverter() this.redeemBy, this.hasRedeemed = false, this.yearlyRewardCap = 0}): super._();
  factory _HouseholdReferral.fromJson(Map<String, dynamic> json) => _$HouseholdReferralFromJson(json);

/// Null until `ensureReferralCode` has made it.
@override final  String? code;
/// The end of the household's first seven days, or null when its age is
/// unknown — then no code can be entered.
@override@NullableTimestampConverter() final  DateTime? redeemBy;
/// Whether this household has already entered somebody else's code.
@override@JsonKey() final  bool hasRedeemed;
/// The most referral months a household gets in a year — the server's
/// rule, said by the server.
@override@JsonKey() final  int yearlyRewardCap;

/// Create a copy of HouseholdReferral
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HouseholdReferralCopyWith<_HouseholdReferral> get copyWith => __$HouseholdReferralCopyWithImpl<_HouseholdReferral>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HouseholdReferralToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _HouseholdReferral&&(identical(other.code, code) || other.code == code)&&(identical(other.redeemBy, redeemBy) || other.redeemBy == redeemBy)&&(identical(other.hasRedeemed, hasRedeemed) || other.hasRedeemed == hasRedeemed)&&(identical(other.yearlyRewardCap, yearlyRewardCap) || other.yearlyRewardCap == yearlyRewardCap));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,code,redeemBy,hasRedeemed,yearlyRewardCap);
}

@override
String toString() {
    return 'HouseholdReferral(code: $code, redeemBy: $redeemBy, hasRedeemed: $hasRedeemed, yearlyRewardCap: $yearlyRewardCap)';
}


}

/// @nodoc
abstract mixin class _$HouseholdReferralCopyWith<$Res> implements $HouseholdReferralCopyWith<$Res> {
  factory _$HouseholdReferralCopyWith(_HouseholdReferral value, $Res Function(_HouseholdReferral) _then) = __$HouseholdReferralCopyWithImpl;
@override @useResult
$Res call({
 String? code,@NullableTimestampConverter() DateTime? redeemBy, bool hasRedeemed, int yearlyRewardCap
});




}
/// @nodoc
class __$HouseholdReferralCopyWithImpl<$Res>
    implements _$HouseholdReferralCopyWith<$Res> {
  __$HouseholdReferralCopyWithImpl(this._self, this._then);

  final _HouseholdReferral _self;
  final $Res Function(_HouseholdReferral) _then;

/// Create a copy of HouseholdReferral
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = freezed,Object? redeemBy = freezed,Object? hasRedeemed = null,Object? yearlyRewardCap = null,}) {
  return _then(_HouseholdReferral(
code: freezed == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String?,redeemBy: freezed == redeemBy ? _self.redeemBy : redeemBy // ignore: cast_nullable_to_non_nullable
as DateTime?,hasRedeemed: null == hasRedeemed ? _self.hasRedeemed : hasRedeemed // ignore: cast_nullable_to_non_nullable
as bool,yearlyRewardCap: null == yearlyRewardCap ? _self.yearlyRewardCap : yearlyRewardCap // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
