// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'entitlement.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Entitlement {

/// Premium until this instant, or none. The rules compare it with the
/// request's time, so premium ends at it with nothing having to notice.
@NullableTimestampConverter() DateTime? get premiumUntil;/// A status this build has never heard of reads as none: the date above
/// still says whether there is premium (`BE-10`).
@JsonKey(unknownEnumValue: EntitlementStatus.none) EntitlementStatus get status;@JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) SubscriptionPlan? get plan;@JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) BillingStore? get store;/// Null when the store has not said.
 bool? get willRenew;/// Who bought it — the one person whose store account can change it.
 String? get managedByMemberId;/// A sandbox or licence-tester purchase.
 bool get isTest;
/// Create a copy of Entitlement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EntitlementCopyWith<Entitlement> get copyWith => _$EntitlementCopyWithImpl<Entitlement>(this as Entitlement, _$identity);

  /// Serializes this Entitlement to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Entitlement;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Entitlement&&(identical(other.premiumUntil, _this.premiumUntil) || other.premiumUntil == _this.premiumUntil)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.plan, _this.plan) || other.plan == _this.plan)&&(identical(other.store, _this.store) || other.store == _this.store)&&(identical(other.willRenew, _this.willRenew) || other.willRenew == _this.willRenew)&&(identical(other.managedByMemberId, _this.managedByMemberId) || other.managedByMemberId == _this.managedByMemberId)&&(identical(other.isTest, _this.isTest) || other.isTest == _this.isTest));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Entitlement;
  return Object.hash(runtimeType,_this.premiumUntil,_this.status,_this.plan,_this.store,_this.willRenew,_this.managedByMemberId,_this.isTest);
}

@override
String toString() {
  final _this = this as Entitlement;
  return 'Entitlement(premiumUntil: ${_this.premiumUntil}, status: ${_this.status}, plan: ${_this.plan}, store: ${_this.store}, willRenew: ${_this.willRenew}, managedByMemberId: ${_this.managedByMemberId}, isTest: ${_this.isTest})';
}


}

/// @nodoc
abstract mixin class $EntitlementCopyWith<$Res>  {
  factory $EntitlementCopyWith(Entitlement value, $Res Function(Entitlement) _then) = _$EntitlementCopyWithImpl;
@useResult
$Res call({
@NullableTimestampConverter() DateTime? premiumUntil,@JsonKey(unknownEnumValue: EntitlementStatus.none) EntitlementStatus status,@JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) SubscriptionPlan? plan,@JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) BillingStore? store, bool? willRenew, String? managedByMemberId, bool isTest
});




}
/// @nodoc
class _$EntitlementCopyWithImpl<$Res>
    implements $EntitlementCopyWith<$Res> {
  _$EntitlementCopyWithImpl(this._self, this._then);

  final Entitlement _self;
  final $Res Function(Entitlement) _then;

/// Create a copy of Entitlement
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? premiumUntil = freezed,Object? status = null,Object? plan = freezed,Object? store = freezed,Object? willRenew = freezed,Object? managedByMemberId = freezed,Object? isTest = null,}) {
  return _then(Entitlement(
premiumUntil: freezed == premiumUntil ? _self.premiumUntil : premiumUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as EntitlementStatus,plan: freezed == plan ? _self.plan : plan // ignore: cast_nullable_to_non_nullable
as SubscriptionPlan?,store: freezed == store ? _self.store : store // ignore: cast_nullable_to_non_nullable
as BillingStore?,willRenew: freezed == willRenew ? _self.willRenew : willRenew // ignore: cast_nullable_to_non_nullable
as bool?,managedByMemberId: freezed == managedByMemberId ? _self.managedByMemberId : managedByMemberId // ignore: cast_nullable_to_non_nullable
as String?,isTest: null == isTest ? _self.isTest : isTest // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Entitlement].
extension EntitlementPatterns on Entitlement {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Entitlement value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Entitlement() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Entitlement value)  $default,){
final _that = this;
switch (_that) {
case _Entitlement():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Entitlement value)?  $default,){
final _that = this;
switch (_that) {
case _Entitlement() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@NullableTimestampConverter()  DateTime? premiumUntil, @JsonKey(unknownEnumValue: EntitlementStatus.none)  EntitlementStatus status, @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)  SubscriptionPlan? plan, @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)  BillingStore? store,  bool? willRenew,  String? managedByMemberId,  bool isTest)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Entitlement() when $default != null:
return $default(_that.premiumUntil,_that.status,_that.plan,_that.store,_that.willRenew,_that.managedByMemberId,_that.isTest);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@NullableTimestampConverter()  DateTime? premiumUntil, @JsonKey(unknownEnumValue: EntitlementStatus.none)  EntitlementStatus status, @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)  SubscriptionPlan? plan, @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)  BillingStore? store,  bool? willRenew,  String? managedByMemberId,  bool isTest)  $default,) {final _that = this;
switch (_that) {
case _Entitlement():
return $default(_that.premiumUntil,_that.status,_that.plan,_that.store,_that.willRenew,_that.managedByMemberId,_that.isTest);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@NullableTimestampConverter()  DateTime? premiumUntil, @JsonKey(unknownEnumValue: EntitlementStatus.none)  EntitlementStatus status, @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)  SubscriptionPlan? plan, @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)  BillingStore? store,  bool? willRenew,  String? managedByMemberId,  bool isTest)?  $default,) {final _that = this;
switch (_that) {
case _Entitlement() when $default != null:
return $default(_that.premiumUntil,_that.status,_that.plan,_that.store,_that.willRenew,_that.managedByMemberId,_that.isTest);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Entitlement extends Entitlement {
  const _Entitlement({@NullableTimestampConverter() this.premiumUntil, @JsonKey(unknownEnumValue: EntitlementStatus.none) this.status = EntitlementStatus.none, @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) this.plan, @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) this.store, this.willRenew, this.managedByMemberId, this.isTest = false}): super._();
  factory _Entitlement.fromJson(Map<String, dynamic> json) => _$EntitlementFromJson(json);

/// Premium until this instant, or none. The rules compare it with the
/// request's time, so premium ends at it with nothing having to notice.
@override@NullableTimestampConverter() final  DateTime? premiumUntil;
/// A status this build has never heard of reads as none: the date above
/// still says whether there is premium (`BE-10`).
@override@JsonKey(unknownEnumValue: EntitlementStatus.none) final  EntitlementStatus status;
@override@JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) final  SubscriptionPlan? plan;
@override@JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) final  BillingStore? store;
/// Null when the store has not said.
@override final  bool? willRenew;
/// Who bought it — the one person whose store account can change it.
@override final  String? managedByMemberId;
/// A sandbox or licence-tester purchase.
@override@JsonKey() final  bool isTest;

/// Create a copy of Entitlement
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EntitlementCopyWith<_Entitlement> get copyWith => __$EntitlementCopyWithImpl<_Entitlement>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EntitlementToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Entitlement&&(identical(other.premiumUntil, premiumUntil) || other.premiumUntil == premiumUntil)&&(identical(other.status, status) || other.status == status)&&(identical(other.plan, plan) || other.plan == plan)&&(identical(other.store, store) || other.store == store)&&(identical(other.willRenew, willRenew) || other.willRenew == willRenew)&&(identical(other.managedByMemberId, managedByMemberId) || other.managedByMemberId == managedByMemberId)&&(identical(other.isTest, isTest) || other.isTest == isTest));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,premiumUntil,status,plan,store,willRenew,managedByMemberId,isTest);
}

@override
String toString() {
    return 'Entitlement(premiumUntil: $premiumUntil, status: $status, plan: $plan, store: $store, willRenew: $willRenew, managedByMemberId: $managedByMemberId, isTest: $isTest)';
}


}

/// @nodoc
abstract mixin class _$EntitlementCopyWith<$Res> implements $EntitlementCopyWith<$Res> {
  factory _$EntitlementCopyWith(_Entitlement value, $Res Function(_Entitlement) _then) = __$EntitlementCopyWithImpl;
@override @useResult
$Res call({
@NullableTimestampConverter() DateTime? premiumUntil,@JsonKey(unknownEnumValue: EntitlementStatus.none) EntitlementStatus status,@JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) SubscriptionPlan? plan,@JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) BillingStore? store, bool? willRenew, String? managedByMemberId, bool isTest
});




}
/// @nodoc
class __$EntitlementCopyWithImpl<$Res>
    implements _$EntitlementCopyWith<$Res> {
  __$EntitlementCopyWithImpl(this._self, this._then);

  final _Entitlement _self;
  final $Res Function(_Entitlement) _then;

/// Create a copy of Entitlement
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? premiumUntil = freezed,Object? status = null,Object? plan = freezed,Object? store = freezed,Object? willRenew = freezed,Object? managedByMemberId = freezed,Object? isTest = null,}) {
  return _then(_Entitlement(
premiumUntil: freezed == premiumUntil ? _self.premiumUntil : premiumUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as EntitlementStatus,plan: freezed == plan ? _self.plan : plan // ignore: cast_nullable_to_non_nullable
as SubscriptionPlan?,store: freezed == store ? _self.store : store // ignore: cast_nullable_to_non_nullable
as BillingStore?,willRenew: freezed == willRenew ? _self.willRenew : willRenew // ignore: cast_nullable_to_non_nullable
as bool?,managedByMemberId: freezed == managedByMemberId ? _self.managedByMemberId : managedByMemberId // ignore: cast_nullable_to_non_nullable
as String?,isTest: null == isTest ? _self.isTest : isTest // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
