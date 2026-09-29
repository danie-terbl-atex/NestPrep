// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reward_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RewardRequest _$RewardRequestFromJson(Map<String, dynamic> json) =>
    _RewardRequest(
      id: json['id'] as String,
      rewardId: json['rewardId'] as String,
      memberId: json['memberId'] as String,
      requestedBy: json['requestedBy'] as String,
      requestedAt: const ServerTimestampConverter().fromJson(
        json['requestedAt'],
      ),
      status: $enumDecodeNullable(
        _$RequestStatusEnumMap,
        json['status'],
        unknownValue: RequestStatus.refused,
      ),
      title: json['title'] as String?,
      cost: (json['cost'] as num?)?.toInt(),
      icon: $enumDecodeNullable(
        _$RewardIconEnumMap,
        json['icon'],
        unknownValue: RewardIcon.gift,
      ),
      refusal: $enumDecodeNullable(
        _$RequestRefusalEnumMap,
        json['refusal'],
        unknownValue: RequestRefusal.rewardGone,
      ),
      settledAt: const NullableTimestampConverter().fromJson(json['settledAt']),
    );

Map<String, dynamic> _$RewardRequestToJson(
  _RewardRequest instance,
) => <String, dynamic>{
  'rewardId': instance.rewardId,
  'memberId': instance.memberId,
  'requestedBy': instance.requestedBy,
  'requestedAt': const ServerTimestampConverter().toJson(instance.requestedAt),
};

const _$RequestStatusEnumMap = {
  RequestStatus.waiting: 'waiting',
  RequestStatus.fulfilled: 'fulfilled',
  RequestStatus.declined: 'declined',
  RequestStatus.refused: 'refused',
};

const _$RewardIconEnumMap = {
  RewardIcon.gift: 'gift',
  RewardIcon.treat: 'treat',
  RewardIcon.iceCream: 'iceCream',
  RewardIcon.screenTime: 'screenTime',
  RewardIcon.movie: 'movie',
  RewardIcon.game: 'game',
  RewardIcon.outing: 'outing',
  RewardIcon.book: 'book',
  RewardIcon.toy: 'toy',
  RewardIcon.lateNight: 'lateNight',
};

const _$RequestRefusalEnumMap = {
  RequestRefusal.notEnoughPoints: 'notEnoughPoints',
  RequestRefusal.rewardGone: 'rewardGone',
  RequestRefusal.notAKid: 'notAKid',
};
