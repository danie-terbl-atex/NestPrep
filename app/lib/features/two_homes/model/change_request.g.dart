// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'change_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ChangeRequest _$ChangeRequestFromJson(Map<String, dynamic> json) =>
    _ChangeRequest(
      id: json['id'] as String,
      kind: $enumDecode(
        _$ChangeKindEnumMap,
        json['kind'],
        unknownValue: ChangeKind.swap,
      ),
      from: const NullableCalendarDateConverter().fromJson(json['from']),
      to: const NullableCalendarDateConverter().fromJson(json['to']),
      toSide: $enumDecodeNullable(
        _$CustodySideEnumMap,
        json['toSide'],
        unknownValue: JsonKey.nullForUndefinedEnumValue,
      ),
      schedule: json['schedule'] == null
          ? null
          : CustodySchedule.fromJson(json['schedule'] as Map<String, dynamic>),
      note: json['note'] as String?,
      proposedBySide: $enumDecode(_$CustodySideEnumMap, json['proposedBySide']),
      status: $enumDecode(
        _$RequestStatusEnumMap,
        json['status'],
        unknownValue: RequestStatus.closed,
      ),
      createdAt: const ServerTimestampConverter().fromJson(json['createdAt']),
      answeredAt: const NullableTimestampConverter().fromJson(
        json['answeredAt'],
      ),
      answeredBySide: $enumDecodeNullable(
        _$CustodySideEnumMap,
        json['answeredBySide'],
        unknownValue: JsonKey.nullForUndefinedEnumValue,
      ),
      answerNote: json['answerNote'] as String?,
    );

Map<String, dynamic> _$ChangeRequestToJson(
  _ChangeRequest instance,
) => <String, dynamic>{
  'kind': _$ChangeKindEnumMap[instance.kind]!,
  'from': const NullableCalendarDateConverter().toJson(instance.from),
  'to': const NullableCalendarDateConverter().toJson(instance.to),
  'toSide': _$CustodySideEnumMap[instance.toSide],
  'schedule': instance.schedule?.toJson(),
  'note': instance.note,
  'proposedBySide': _$CustodySideEnumMap[instance.proposedBySide]!,
  'status': _$RequestStatusEnumMap[instance.status]!,
  'createdAt': const ServerTimestampConverter().toJson(instance.createdAt),
  'answeredAt': const NullableTimestampConverter().toJson(instance.answeredAt),
  'answeredBySide': _$CustodySideEnumMap[instance.answeredBySide],
  'answerNote': instance.answerNote,
};

const _$ChangeKindEnumMap = {
  ChangeKind.swap: 'swap',
  ChangeKind.schedule: 'schedule',
};

const _$CustodySideEnumMap = {CustodySide.a: 'a', CustodySide.b: 'b'};

const _$RequestStatusEnumMap = {
  RequestStatus.pending: 'pending',
  RequestStatus.accepted: 'accepted',
  RequestStatus.declined: 'declined',
  RequestStatus.withdrawn: 'withdrawn',
  RequestStatus.closed: 'closed',
};
