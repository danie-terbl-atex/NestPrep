// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'assistant_connection.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AssistantConnection _$AssistantConnectionFromJson(
  Map<String, dynamic> json,
) => _AssistantConnection(
  id: json['id'] as String,
  uid: json['uid'] as String,
  memberId: json['memberId'] as String,
  clientName: json['clientName'] as String? ?? '',
  host: json['host'] as String? ?? '',
  via:
      $enumDecodeNullable(
        _$AssistantViaEnumMap,
        json['via'],
        unknownValue: AssistantVia.assistant,
      ) ??
      AssistantVia.assistant,
  scopes:
      (json['scopes'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  createdAt: const NullableTimestampConverter().fromJson(json['createdAt']),
  lastUsedAt: const NullableTimestampConverter().fromJson(json['lastUsedAt']),
);

Map<String, dynamic> _$AssistantConnectionToJson(
  _AssistantConnection instance,
) => <String, dynamic>{
  'uid': instance.uid,
  'memberId': instance.memberId,
  'clientName': instance.clientName,
  'host': instance.host,
  'via': _$AssistantViaEnumMap[instance.via]!,
  'scopes': instance.scopes,
  'createdAt': const NullableTimestampConverter().toJson(instance.createdAt),
  'lastUsedAt': const NullableTimestampConverter().toJson(instance.lastUsedAt),
};

const _$AssistantViaEnumMap = {
  AssistantVia.claude: 'claude',
  AssistantVia.chatgpt: 'chatgpt',
  AssistantVia.assistant: 'assistant',
};
