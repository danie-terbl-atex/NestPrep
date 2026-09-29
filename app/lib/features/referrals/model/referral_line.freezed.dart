// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'referral_line.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ReferralLine {

@JsonKey(includeToJson: false) String get id;@JsonKey(unknownEnumValue: ReferralSide.referred) ReferralSide get side;/// A status this build has never heard of reads as pending (`BE-10`).
@JsonKey(unknownEnumValue: ReferralStatus.pending) ReferralStatus get status;@NullableTimestampConverter() DateTime? get redeemedAt;/// The server's deadline for the new household to become a family.
@NullableTimestampConverter() DateTime? get qualifyBy;@NullableTimestampConverter() DateTime? get qualifiedAt;@JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) ReferralReward? get reward;
/// Create a copy of ReferralLine
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReferralLineCopyWith<ReferralLine> get copyWith => _$ReferralLineCopyWithImpl<ReferralLine>(this as ReferralLine, _$identity);

  /// Serializes this ReferralLine to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ReferralLine;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReferralLine&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.side, _this.side) || other.side == _this.side)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.redeemedAt, _this.redeemedAt) || other.redeemedAt == _this.redeemedAt)&&(identical(other.qualifyBy, _this.qualifyBy) || other.qualifyBy == _this.qualifyBy)&&(identical(other.qualifiedAt, _this.qualifiedAt) || other.qualifiedAt == _this.qualifiedAt)&&(identical(other.reward, _this.reward) || other.reward == _this.reward));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ReferralLine;
  return Object.hash(runtimeType,_this.id,_this.side,_this.status,_this.redeemedAt,_this.qualifyBy,_this.qualifiedAt,_this.reward);
}

@override
String toString() {
  final _this = this as ReferralLine;
  return 'ReferralLine(id: ${_this.id}, side: ${_this.side}, status: ${_this.status}, redeemedAt: ${_this.redeemedAt}, qualifyBy: ${_this.qualifyBy}, qualifiedAt: ${_this.qualifiedAt}, reward: ${_this.reward})';
}


}

/// @nodoc
abstract mixin class $ReferralLineCopyWith<$Res>  {
  factory $ReferralLineCopyWith(ReferralLine value, $Res Function(ReferralLine) _then) = _$ReferralLineCopyWithImpl;
@useResult
$Res call({
@JsonKey(includeToJson: false) String id,@JsonKey(unknownEnumValue: ReferralSide.referred) ReferralSide side,@JsonKey(unknownEnumValue: ReferralStatus.pending) ReferralStatus status,@NullableTimestampConverter() DateTime? redeemedAt,@NullableTimestampConverter() DateTime? qualifyBy,@NullableTimestampConverter() DateTime? qualifiedAt,@JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) ReferralReward? reward
});




}
/// @nodoc
class _$ReferralLineCopyWithImpl<$Res>
    implements $ReferralLineCopyWith<$Res> {
  _$ReferralLineCopyWithImpl(this._self, this._then);

  final ReferralLine _self;
  final $Res Function(ReferralLine) _then;

/// Create a copy of ReferralLine
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? side = null,Object? status = null,Object? redeemedAt = freezed,Object? qualifyBy = freezed,Object? qualifiedAt = freezed,Object? reward = freezed,}) {
  return _then(ReferralLine(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,side: null == side ? _self.side : side // ignore: cast_nullable_to_non_nullable
as ReferralSide,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ReferralStatus,redeemedAt: freezed == redeemedAt ? _self.redeemedAt : redeemedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,qualifyBy: freezed == qualifyBy ? _self.qualifyBy : qualifyBy // ignore: cast_nullable_to_non_nullable
as DateTime?,qualifiedAt: freezed == qualifiedAt ? _self.qualifiedAt : qualifiedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,reward: freezed == reward ? _self.reward : reward // ignore: cast_nullable_to_non_nullable
as ReferralReward?,
  ));
}

}


/// Adds pattern-matching-related methods to [ReferralLine].
extension ReferralLinePatterns on ReferralLine {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReferralLine value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReferralLine() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReferralLine value)  $default,){
final _that = this;
switch (_that) {
case _ReferralLine():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReferralLine value)?  $default,){
final _that = this;
switch (_that) {
case _ReferralLine() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id, @JsonKey(unknownEnumValue: ReferralSide.referred)  ReferralSide side, @JsonKey(unknownEnumValue: ReferralStatus.pending)  ReferralStatus status, @NullableTimestampConverter()  DateTime? redeemedAt, @NullableTimestampConverter()  DateTime? qualifyBy, @NullableTimestampConverter()  DateTime? qualifiedAt, @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)  ReferralReward? reward)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReferralLine() when $default != null:
return $default(_that.id,_that.side,_that.status,_that.redeemedAt,_that.qualifyBy,_that.qualifiedAt,_that.reward);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id, @JsonKey(unknownEnumValue: ReferralSide.referred)  ReferralSide side, @JsonKey(unknownEnumValue: ReferralStatus.pending)  ReferralStatus status, @NullableTimestampConverter()  DateTime? redeemedAt, @NullableTimestampConverter()  DateTime? qualifyBy, @NullableTimestampConverter()  DateTime? qualifiedAt, @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)  ReferralReward? reward)  $default,) {final _that = this;
switch (_that) {
case _ReferralLine():
return $default(_that.id,_that.side,_that.status,_that.redeemedAt,_that.qualifyBy,_that.qualifiedAt,_that.reward);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(includeToJson: false)  String id, @JsonKey(unknownEnumValue: ReferralSide.referred)  ReferralSide side, @JsonKey(unknownEnumValue: ReferralStatus.pending)  ReferralStatus status, @NullableTimestampConverter()  DateTime? redeemedAt, @NullableTimestampConverter()  DateTime? qualifyBy, @NullableTimestampConverter()  DateTime? qualifiedAt, @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)  ReferralReward? reward)?  $default,) {final _that = this;
switch (_that) {
case _ReferralLine() when $default != null:
return $default(_that.id,_that.side,_that.status,_that.redeemedAt,_that.qualifyBy,_that.qualifiedAt,_that.reward);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ReferralLine extends ReferralLine {
  const _ReferralLine({@JsonKey(includeToJson: false) required this.id, @JsonKey(unknownEnumValue: ReferralSide.referred) this.side = ReferralSide.referred, @JsonKey(unknownEnumValue: ReferralStatus.pending) this.status = ReferralStatus.pending, @NullableTimestampConverter() this.redeemedAt, @NullableTimestampConverter() this.qualifyBy, @NullableTimestampConverter() this.qualifiedAt, @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) this.reward}): super._();
  factory _ReferralLine.fromJson(Map<String, dynamic> json) => _$ReferralLineFromJson(json);

@override@JsonKey(includeToJson: false) final  String id;
@override@JsonKey(unknownEnumValue: ReferralSide.referred) final  ReferralSide side;
/// A status this build has never heard of reads as pending (`BE-10`).
@override@JsonKey(unknownEnumValue: ReferralStatus.pending) final  ReferralStatus status;
@override@NullableTimestampConverter() final  DateTime? redeemedAt;
/// The server's deadline for the new household to become a family.
@override@NullableTimestampConverter() final  DateTime? qualifyBy;
@override@NullableTimestampConverter() final  DateTime? qualifiedAt;
@override@JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) final  ReferralReward? reward;

/// Create a copy of ReferralLine
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReferralLineCopyWith<_ReferralLine> get copyWith => __$ReferralLineCopyWithImpl<_ReferralLine>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReferralLineToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReferralLine&&(identical(other.id, id) || other.id == id)&&(identical(other.side, side) || other.side == side)&&(identical(other.status, status) || other.status == status)&&(identical(other.redeemedAt, redeemedAt) || other.redeemedAt == redeemedAt)&&(identical(other.qualifyBy, qualifyBy) || other.qualifyBy == qualifyBy)&&(identical(other.qualifiedAt, qualifiedAt) || other.qualifiedAt == qualifiedAt)&&(identical(other.reward, reward) || other.reward == reward));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,side,status,redeemedAt,qualifyBy,qualifiedAt,reward);
}

@override
String toString() {
    return 'ReferralLine(id: $id, side: $side, status: $status, redeemedAt: $redeemedAt, qualifyBy: $qualifyBy, qualifiedAt: $qualifiedAt, reward: $reward)';
}


}

/// @nodoc
abstract mixin class _$ReferralLineCopyWith<$Res> implements $ReferralLineCopyWith<$Res> {
  factory _$ReferralLineCopyWith(_ReferralLine value, $Res Function(_ReferralLine) _then) = __$ReferralLineCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(includeToJson: false) String id,@JsonKey(unknownEnumValue: ReferralSide.referred) ReferralSide side,@JsonKey(unknownEnumValue: ReferralStatus.pending) ReferralStatus status,@NullableTimestampConverter() DateTime? redeemedAt,@NullableTimestampConverter() DateTime? qualifyBy,@NullableTimestampConverter() DateTime? qualifiedAt,@JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) ReferralReward? reward
});




}
/// @nodoc
class __$ReferralLineCopyWithImpl<$Res>
    implements _$ReferralLineCopyWith<$Res> {
  __$ReferralLineCopyWithImpl(this._self, this._then);

  final _ReferralLine _self;
  final $Res Function(_ReferralLine) _then;

/// Create a copy of ReferralLine
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? side = null,Object? status = null,Object? redeemedAt = freezed,Object? qualifyBy = freezed,Object? qualifiedAt = freezed,Object? reward = freezed,}) {
  return _then(_ReferralLine(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,side: null == side ? _self.side : side // ignore: cast_nullable_to_non_nullable
as ReferralSide,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ReferralStatus,redeemedAt: freezed == redeemedAt ? _self.redeemedAt : redeemedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,qualifyBy: freezed == qualifyBy ? _self.qualifyBy : qualifyBy // ignore: cast_nullable_to_non_nullable
as DateTime?,qualifiedAt: freezed == qualifiedAt ? _self.qualifiedAt : qualifiedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,reward: freezed == reward ? _self.reward : reward // ignore: cast_nullable_to_non_nullable
as ReferralReward?,
  ));
}


}

// dart format on
