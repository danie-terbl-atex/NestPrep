// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'school_run.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SchoolRun _$SchoolRunFromJson(Map<String, dynamic> json) => _SchoolRun(
  id: json['id'] as String,
  childId: json['childId'] as String,
  weekday: (json['weekday'] as num).toInt(),
  personId: json['personId'] as String?,
  memberId: json['memberId'] as String?,
  atMinute: (json['atMinute'] as num?)?.toInt(),
  place: json['place'] as String?,
  updatedBy: json['updatedBy'] as String,
  updatedAt: const ServerTimestampConverter().fromJson(json['updatedAt']),
);

Map<String, dynamic> _$SchoolRunToJson(_SchoolRun instance) =>
    <String, dynamic>{
      'childId': instance.childId,
      'weekday': instance.weekday,
      'personId': instance.personId,
      'memberId': instance.memberId,
      'atMinute': instance.atMinute,
      'place': instance.place,
      'updatedBy': instance.updatedBy,
      'updatedAt': const ServerTimestampConverter().toJson(instance.updatedAt),
    };
