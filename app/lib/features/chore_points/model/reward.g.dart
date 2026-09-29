// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reward.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Reward _$RewardFromJson(Map<String, dynamic> json) => _Reward(
  id: json['id'] as String,
  title: json['title'] as String,
  cost: (json['cost'] as num).toInt(),
  icon:
      $enumDecodeNullable(
        _$RewardIconEnumMap,
        json['icon'],
        unknownValue: RewardIcon.gift,
      ) ??
      RewardIcon.gift,
  createdBy: json['createdBy'] as String,
  createdAt: const ServerTimestampConverter().fromJson(json['createdAt']),
);

Map<String, dynamic> _$RewardToJson(_Reward instance) => <String, dynamic>{
  'title': instance.title,
  'cost': instance.cost,
  'icon': _$RewardIconEnumMap[instance.icon]!,
  'createdBy': instance.createdBy,
  'createdAt': const ServerTimestampConverter().toJson(instance.createdAt),
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
