// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'entitlement.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Entitlement _$EntitlementFromJson(Map<String, dynamic> json) => _Entitlement(
  premiumUntil: const NullableTimestampConverter().fromJson(
    json['premiumUntil'],
  ),
  status:
      $enumDecodeNullable(
        _$EntitlementStatusEnumMap,
        json['status'],
        unknownValue: EntitlementStatus.none,
      ) ??
      EntitlementStatus.none,
  plan: $enumDecodeNullable(
    _$SubscriptionPlanEnumMap,
    json['plan'],
    unknownValue: JsonKey.nullForUndefinedEnumValue,
  ),
  store: $enumDecodeNullable(
    _$BillingStoreEnumMap,
    json['store'],
    unknownValue: JsonKey.nullForUndefinedEnumValue,
  ),
  willRenew: json['willRenew'] as bool?,
  managedByMemberId: json['managedByMemberId'] as String?,
  isTest: json['isTest'] as bool? ?? false,
  storeUntil: const NullableTimestampConverter().fromJson(json['storeUntil']),
  referralUntil: const NullableTimestampConverter().fromJson(
    json['referralUntil'],
  ),
  referralDaysWaiting: (json['referralDaysWaiting'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$EntitlementToJson(
  _Entitlement instance,
) => <String, dynamic>{
  'premiumUntil': const NullableTimestampConverter().toJson(
    instance.premiumUntil,
  ),
  'status': _$EntitlementStatusEnumMap[instance.status]!,
  'plan': _$SubscriptionPlanEnumMap[instance.plan],
  'store': _$BillingStoreEnumMap[instance.store],
  'willRenew': instance.willRenew,
  'managedByMemberId': instance.managedByMemberId,
  'isTest': instance.isTest,
  'storeUntil': const NullableTimestampConverter().toJson(instance.storeUntil),
  'referralUntil': const NullableTimestampConverter().toJson(
    instance.referralUntil,
  ),
  'referralDaysWaiting': instance.referralDaysWaiting,
};

const _$EntitlementStatusEnumMap = {
  EntitlementStatus.none: 'none',
  EntitlementStatus.active: 'active',
  EntitlementStatus.cancelled: 'cancelled',
  EntitlementStatus.inGracePeriod: 'inGracePeriod',
  EntitlementStatus.onHold: 'onHold',
  EntitlementStatus.paused: 'paused',
  EntitlementStatus.pending: 'pending',
  EntitlementStatus.expired: 'expired',
  EntitlementStatus.revoked: 'revoked',
};

const _$SubscriptionPlanEnumMap = {
  SubscriptionPlan.monthly: 'monthly',
  SubscriptionPlan.yearly: 'yearly',
};

const _$BillingStoreEnumMap = {
  BillingStore.appStore: 'appStore',
  BillingStore.playStore: 'playStore',
};
