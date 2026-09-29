// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'point_balance.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PointBalance _$PointBalanceFromJson(Map<String, dynamic> json) =>
    _PointBalance(
      id: json['id'] as String,
      balance: (json['balance'] as num?)?.toInt() ?? 0,
      earned: (json['earned'] as num?)?.toInt() ?? 0,
      spent: (json['spent'] as num?)?.toInt() ?? 0,
      streakDays: (json['streakDays'] as num?)?.toInt() ?? 0,
      bestStreak: (json['bestStreak'] as num?)?.toInt() ?? 0,
      streakLastDay: const NullableCalendarDateConverter().fromJson(
        json['streakLastDay'],
      ),
      updatedAt: const NullableTimestampConverter().fromJson(json['updatedAt']),
    );

Map<String, dynamic> _$PointBalanceToJson(
  _PointBalance instance,
) => <String, dynamic>{
  'balance': instance.balance,
  'earned': instance.earned,
  'spent': instance.spent,
  'streakDays': instance.streakDays,
  'bestStreak': instance.bestStreak,
  'streakLastDay': const NullableCalendarDateConverter().toJson(
    instance.streakLastDay,
  ),
  'updatedAt': const NullableTimestampConverter().toJson(instance.updatedAt),
};
