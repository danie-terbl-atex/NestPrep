// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'reward_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RewardRequest {

@JsonKey(includeToJson: false) String get id; String get rewardId;/// The child it is for.
 String get memberId;/// Who asked: the child, or a parent on the child's behalf.
 String get requestedBy;@ServerTimestampConverter() DateTime? get requestedAt;@JsonKey(includeToJson: false, unknownEnumValue: RequestStatus.refused) RequestStatus? get status;@JsonKey(includeToJson: false) String? get title;@JsonKey(includeToJson: false) int? get cost;@JsonKey(includeToJson: false, unknownEnumValue: RewardIcon.gift) RewardIcon? get icon;@JsonKey(includeToJson: false, unknownEnumValue: RequestRefusal.rewardGone) RequestRefusal? get refusal;@JsonKey(includeToJson: false)@NullableTimestampConverter() DateTime? get settledAt;
/// Create a copy of RewardRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RewardRequestCopyWith<RewardRequest> get copyWith => _$RewardRequestCopyWithImpl<RewardRequest>(this as RewardRequest, _$identity);

  /// Serializes this RewardRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as RewardRequest;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RewardRequest&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.rewardId, _this.rewardId) || other.rewardId == _this.rewardId)&&(identical(other.memberId, _this.memberId) || other.memberId == _this.memberId)&&(identical(other.requestedBy, _this.requestedBy) || other.requestedBy == _this.requestedBy)&&(identical(other.requestedAt, _this.requestedAt) || other.requestedAt == _this.requestedAt)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.cost, _this.cost) || other.cost == _this.cost)&&(identical(other.icon, _this.icon) || other.icon == _this.icon)&&(identical(other.refusal, _this.refusal) || other.refusal == _this.refusal)&&(identical(other.settledAt, _this.settledAt) || other.settledAt == _this.settledAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as RewardRequest;
  return Object.hash(runtimeType,_this.id,_this.rewardId,_this.memberId,_this.requestedBy,_this.requestedAt,_this.status,_this.title,_this.cost,_this.icon,_this.refusal,_this.settledAt);
}

@override
String toString() {
  final _this = this as RewardRequest;
  return 'RewardRequest(id: ${_this.id}, rewardId: ${_this.rewardId}, memberId: ${_this.memberId}, requestedBy: ${_this.requestedBy}, requestedAt: ${_this.requestedAt}, status: ${_this.status}, title: ${_this.title}, cost: ${_this.cost}, icon: ${_this.icon}, refusal: ${_this.refusal}, settledAt: ${_this.settledAt})';
}


}

/// @nodoc
abstract mixin class $RewardRequestCopyWith<$Res>  {
  factory $RewardRequestCopyWith(RewardRequest value, $Res Function(RewardRequest) _then) = _$RewardRequestCopyWithImpl;
@useResult
$Res call({
@JsonKey(includeToJson: false) String id, String rewardId, String memberId, String requestedBy,@ServerTimestampConverter() DateTime? requestedAt,@JsonKey(includeToJson: false, unknownEnumValue: RequestStatus.refused) RequestStatus? status,@JsonKey(includeToJson: false) String? title,@JsonKey(includeToJson: false) int? cost,@JsonKey(includeToJson: false, unknownEnumValue: RewardIcon.gift) RewardIcon? icon,@JsonKey(includeToJson: false, unknownEnumValue: RequestRefusal.rewardGone) RequestRefusal? refusal,@JsonKey(includeToJson: false)@NullableTimestampConverter() DateTime? settledAt
});




}
/// @nodoc
class _$RewardRequestCopyWithImpl<$Res>
    implements $RewardRequestCopyWith<$Res> {
  _$RewardRequestCopyWithImpl(this._self, this._then);

  final RewardRequest _self;
  final $Res Function(RewardRequest) _then;

/// Create a copy of RewardRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? rewardId = null,Object? memberId = null,Object? requestedBy = null,Object? requestedAt = freezed,Object? status = freezed,Object? title = freezed,Object? cost = freezed,Object? icon = freezed,Object? refusal = freezed,Object? settledAt = freezed,}) {
  return _then(RewardRequest(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,rewardId: null == rewardId ? _self.rewardId : rewardId // ignore: cast_nullable_to_non_nullable
as String,memberId: null == memberId ? _self.memberId : memberId // ignore: cast_nullable_to_non_nullable
as String,requestedBy: null == requestedBy ? _self.requestedBy : requestedBy // ignore: cast_nullable_to_non_nullable
as String,requestedAt: freezed == requestedAt ? _self.requestedAt : requestedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as RequestStatus?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,cost: freezed == cost ? _self.cost : cost // ignore: cast_nullable_to_non_nullable
as int?,icon: freezed == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as RewardIcon?,refusal: freezed == refusal ? _self.refusal : refusal // ignore: cast_nullable_to_non_nullable
as RequestRefusal?,settledAt: freezed == settledAt ? _self.settledAt : settledAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [RewardRequest].
extension RewardRequestPatterns on RewardRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RewardRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RewardRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RewardRequest value)  $default,){
final _that = this;
switch (_that) {
case _RewardRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RewardRequest value)?  $default,){
final _that = this;
switch (_that) {
case _RewardRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  String rewardId,  String memberId,  String requestedBy, @ServerTimestampConverter()  DateTime? requestedAt, @JsonKey(includeToJson: false, unknownEnumValue: RequestStatus.refused)  RequestStatus? status, @JsonKey(includeToJson: false)  String? title, @JsonKey(includeToJson: false)  int? cost, @JsonKey(includeToJson: false, unknownEnumValue: RewardIcon.gift)  RewardIcon? icon, @JsonKey(includeToJson: false, unknownEnumValue: RequestRefusal.rewardGone)  RequestRefusal? refusal, @JsonKey(includeToJson: false)@NullableTimestampConverter()  DateTime? settledAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RewardRequest() when $default != null:
return $default(_that.id,_that.rewardId,_that.memberId,_that.requestedBy,_that.requestedAt,_that.status,_that.title,_that.cost,_that.icon,_that.refusal,_that.settledAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String id,  String rewardId,  String memberId,  String requestedBy, @ServerTimestampConverter()  DateTime? requestedAt, @JsonKey(includeToJson: false, unknownEnumValue: RequestStatus.refused)  RequestStatus? status, @JsonKey(includeToJson: false)  String? title, @JsonKey(includeToJson: false)  int? cost, @JsonKey(includeToJson: false, unknownEnumValue: RewardIcon.gift)  RewardIcon? icon, @JsonKey(includeToJson: false, unknownEnumValue: RequestRefusal.rewardGone)  RequestRefusal? refusal, @JsonKey(includeToJson: false)@NullableTimestampConverter()  DateTime? settledAt)  $default,) {final _that = this;
switch (_that) {
case _RewardRequest():
return $default(_that.id,_that.rewardId,_that.memberId,_that.requestedBy,_that.requestedAt,_that.status,_that.title,_that.cost,_that.icon,_that.refusal,_that.settledAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(includeToJson: false)  String id,  String rewardId,  String memberId,  String requestedBy, @ServerTimestampConverter()  DateTime? requestedAt, @JsonKey(includeToJson: false, unknownEnumValue: RequestStatus.refused)  RequestStatus? status, @JsonKey(includeToJson: false)  String? title, @JsonKey(includeToJson: false)  int? cost, @JsonKey(includeToJson: false, unknownEnumValue: RewardIcon.gift)  RewardIcon? icon, @JsonKey(includeToJson: false, unknownEnumValue: RequestRefusal.rewardGone)  RequestRefusal? refusal, @JsonKey(includeToJson: false)@NullableTimestampConverter()  DateTime? settledAt)?  $default,) {final _that = this;
switch (_that) {
case _RewardRequest() when $default != null:
return $default(_that.id,_that.rewardId,_that.memberId,_that.requestedBy,_that.requestedAt,_that.status,_that.title,_that.cost,_that.icon,_that.refusal,_that.settledAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RewardRequest extends RewardRequest {
  const _RewardRequest({@JsonKey(includeToJson: false) required this.id, required this.rewardId, required this.memberId, required this.requestedBy, @ServerTimestampConverter() this.requestedAt, @JsonKey(includeToJson: false, unknownEnumValue: RequestStatus.refused) this.status, @JsonKey(includeToJson: false) this.title, @JsonKey(includeToJson: false) this.cost, @JsonKey(includeToJson: false, unknownEnumValue: RewardIcon.gift) this.icon, @JsonKey(includeToJson: false, unknownEnumValue: RequestRefusal.rewardGone) this.refusal, @JsonKey(includeToJson: false)@NullableTimestampConverter() this.settledAt}): super._();
  factory _RewardRequest.fromJson(Map<String, dynamic> json) => _$RewardRequestFromJson(json);

@override@JsonKey(includeToJson: false) final  String id;
@override final  String rewardId;
/// The child it is for.
@override final  String memberId;
/// Who asked: the child, or a parent on the child's behalf.
@override final  String requestedBy;
@override@ServerTimestampConverter() final  DateTime? requestedAt;
@override@JsonKey(includeToJson: false, unknownEnumValue: RequestStatus.refused) final  RequestStatus? status;
@override@JsonKey(includeToJson: false) final  String? title;
@override@JsonKey(includeToJson: false) final  int? cost;
@override@JsonKey(includeToJson: false, unknownEnumValue: RewardIcon.gift) final  RewardIcon? icon;
@override@JsonKey(includeToJson: false, unknownEnumValue: RequestRefusal.rewardGone) final  RequestRefusal? refusal;
@override@JsonKey(includeToJson: false)@NullableTimestampConverter() final  DateTime? settledAt;

/// Create a copy of RewardRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RewardRequestCopyWith<_RewardRequest> get copyWith => __$RewardRequestCopyWithImpl<_RewardRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RewardRequestToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RewardRequest&&(identical(other.id, id) || other.id == id)&&(identical(other.rewardId, rewardId) || other.rewardId == rewardId)&&(identical(other.memberId, memberId) || other.memberId == memberId)&&(identical(other.requestedBy, requestedBy) || other.requestedBy == requestedBy)&&(identical(other.requestedAt, requestedAt) || other.requestedAt == requestedAt)&&(identical(other.status, status) || other.status == status)&&(identical(other.title, title) || other.title == title)&&(identical(other.cost, cost) || other.cost == cost)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.refusal, refusal) || other.refusal == refusal)&&(identical(other.settledAt, settledAt) || other.settledAt == settledAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,rewardId,memberId,requestedBy,requestedAt,status,title,cost,icon,refusal,settledAt);
}

@override
String toString() {
    return 'RewardRequest(id: $id, rewardId: $rewardId, memberId: $memberId, requestedBy: $requestedBy, requestedAt: $requestedAt, status: $status, title: $title, cost: $cost, icon: $icon, refusal: $refusal, settledAt: $settledAt)';
}


}

/// @nodoc
abstract mixin class _$RewardRequestCopyWith<$Res> implements $RewardRequestCopyWith<$Res> {
  factory _$RewardRequestCopyWith(_RewardRequest value, $Res Function(_RewardRequest) _then) = __$RewardRequestCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(includeToJson: false) String id, String rewardId, String memberId, String requestedBy,@ServerTimestampConverter() DateTime? requestedAt,@JsonKey(includeToJson: false, unknownEnumValue: RequestStatus.refused) RequestStatus? status,@JsonKey(includeToJson: false) String? title,@JsonKey(includeToJson: false) int? cost,@JsonKey(includeToJson: false, unknownEnumValue: RewardIcon.gift) RewardIcon? icon,@JsonKey(includeToJson: false, unknownEnumValue: RequestRefusal.rewardGone) RequestRefusal? refusal,@JsonKey(includeToJson: false)@NullableTimestampConverter() DateTime? settledAt
});




}
/// @nodoc
class __$RewardRequestCopyWithImpl<$Res>
    implements _$RewardRequestCopyWith<$Res> {
  __$RewardRequestCopyWithImpl(this._self, this._then);

  final _RewardRequest _self;
  final $Res Function(_RewardRequest) _then;

/// Create a copy of RewardRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? rewardId = null,Object? memberId = null,Object? requestedBy = null,Object? requestedAt = freezed,Object? status = freezed,Object? title = freezed,Object? cost = freezed,Object? icon = freezed,Object? refusal = freezed,Object? settledAt = freezed,}) {
  return _then(_RewardRequest(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,rewardId: null == rewardId ? _self.rewardId : rewardId // ignore: cast_nullable_to_non_nullable
as String,memberId: null == memberId ? _self.memberId : memberId // ignore: cast_nullable_to_non_nullable
as String,requestedBy: null == requestedBy ? _self.requestedBy : requestedBy // ignore: cast_nullable_to_non_nullable
as String,requestedAt: freezed == requestedAt ? _self.requestedAt : requestedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as RequestStatus?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,cost: freezed == cost ? _self.cost : cost // ignore: cast_nullable_to_non_nullable
as int?,icon: freezed == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as RewardIcon?,refusal: freezed == refusal ? _self.refusal : refusal // ignore: cast_nullable_to_non_nullable
as RequestRefusal?,settledAt: freezed == settledAt ? _self.settledAt : settledAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
