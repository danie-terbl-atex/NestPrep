// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'point_claim.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PointClaim _$PointClaimFromJson(Map<String, dynamic> json) => _PointClaim(
  id: json['id'] as String,
  memberId: json['memberId'] as String,
  taskId: json['taskId'] as String,
  occurrenceDate: const CalendarDateConverter().fromJson(
    json['occurrenceDate'],
  ),
  title: json['title'] as String,
  points: (json['points'] as num).toInt(),
  status: $enumDecode(
    _$ClaimStatusEnumMap,
    json['status'],
    unknownValue: ClaimStatus.withdrawn,
  ),
  round: (json['round'] as num?)?.toInt() ?? 1,
  claimedAt: const NullableTimestampConverter().fromJson(json['claimedAt']),
);

Map<String, dynamic> _$PointClaimToJson(
  _PointClaim instance,
) => <String, dynamic>{
  'memberId': instance.memberId,
  'taskId': instance.taskId,
  'occurrenceDate': const CalendarDateConverter().toJson(
    instance.occurrenceDate,
  ),
  'title': instance.title,
  'points': instance.points,
  'status': _$ClaimStatusEnumMap[instance.status]!,
  'round': instance.round,
  'claimedAt': const NullableTimestampConverter().toJson(instance.claimedAt),
};

const _$ClaimStatusEnumMap = {
  ClaimStatus.pending: 'pending',
  ClaimStatus.awarded: 'awarded',
  ClaimStatus.sentBack: 'sentBack',
  ClaimStatus.withdrawn: 'withdrawn',
};
