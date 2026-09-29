// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calendar_connection.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CalendarConnection _$CalendarConnectionFromJson(Map<String, dynamic> json) =>
    _CalendarConnection(
      id: json['id'] as String,
      provider: $enumDecode(
        _$CalendarProviderEnumMap,
        json['provider'],
        unknownValue: CalendarProvider.ics,
      ),
      memberId: json['memberId'] as String,
      ownerUid: json['ownerUid'] as String,
      accountLabel: json['accountLabel'] as String? ?? '',
      status:
          $enumDecodeNullable(
            _$ConnectionStatusEnumMap,
            json['status'],
            unknownValue: ConnectionStatus.unreachable,
          ) ??
          ConnectionStatus.connected,
      eventCount: (json['eventCount'] as num?)?.toInt() ?? 0,
      lastSyncedAt: const NullableTimestampConverter().fromJson(
        json['lastSyncedAt'],
      ),
    );

Map<String, dynamic> _$CalendarConnectionToJson(_CalendarConnection instance) =>
    <String, dynamic>{
      'provider': _$CalendarProviderEnumMap[instance.provider]!,
      'memberId': instance.memberId,
      'ownerUid': instance.ownerUid,
      'accountLabel': instance.accountLabel,
      'status': _$ConnectionStatusEnumMap[instance.status]!,
      'eventCount': instance.eventCount,
      'lastSyncedAt': const NullableTimestampConverter().toJson(
        instance.lastSyncedAt,
      ),
    };

const _$CalendarProviderEnumMap = {
  CalendarProvider.google: 'google',
  CalendarProvider.microsoft: 'microsoft',
  CalendarProvider.ics: 'ics',
};

const _$ConnectionStatusEnumMap = {
  ConnectionStatus.connected: 'connected',
  ConnectionStatus.revoked: 'revoked',
  ConnectionStatus.unreachable: 'unreachable',
  ConnectionStatus.notACalendar: 'notACalendar',
  ConnectionStatus.notConfigured: 'notConfigured',
};
