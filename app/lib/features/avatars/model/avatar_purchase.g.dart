// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'avatar_purchase.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AvatarPurchase _$AvatarPurchaseFromJson(Map<String, dynamic> json) =>
    _AvatarPurchase(
      id: json['id'] as String,
      memberId: json['memberId'] as String,
      accessoryId: json['accessoryId'] as String,
      status: $enumDecodeNullable(
        _$PurchaseStatusEnumMap,
        json['status'],
        unknownValue: PurchaseStatus.refused,
      ),
      reason: $enumDecodeNullable(
        _$PurchaseRefusalEnumMap,
        json['reason'],
        unknownValue: PurchaseRefusal.unknownAccessory,
      ),
    );

Map<String, dynamic> _$AvatarPurchaseToJson(_AvatarPurchase instance) =>
    <String, dynamic>{
      'memberId': instance.memberId,
      'accessoryId': instance.accessoryId,
    };

const _$PurchaseStatusEnumMap = {
  PurchaseStatus.owned: 'owned',
  PurchaseStatus.refused: 'refused',
};

const _$PurchaseRefusalEnumMap = {
  PurchaseRefusal.notEnoughStars: 'notEnoughStars',
  PurchaseRefusal.alreadyOwned: 'alreadyOwned',
  PurchaseRefusal.unknownAccessory: 'unknownAccessory',
  PurchaseRefusal.shopOff: 'shopOff',
  PurchaseRefusal.notAKid: 'notAKid',
};
