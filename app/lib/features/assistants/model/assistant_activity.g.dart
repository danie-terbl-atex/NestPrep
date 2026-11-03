// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'assistant_activity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AssistantActivity _$AssistantActivityFromJson(Map<String, dynamic> json) =>
    _AssistantActivity(
      id: json['id'] as String,
      grantId: json['grantId'] as String,
      memberId: json['memberId'] as String,
      via:
          $enumDecodeNullable(
            _$AssistantViaEnumMap,
            json['via'],
            unknownValue: AssistantVia.assistant,
          ) ??
          AssistantVia.assistant,
      tool: json['tool'] as String,
      at: const NullableTimestampConverter().fromJson(json['at']),
    );

Map<String, dynamic> _$AssistantActivityToJson(_AssistantActivity instance) =>
    <String, dynamic>{
      'grantId': instance.grantId,
      'memberId': instance.memberId,
      'via': _$AssistantViaEnumMap[instance.via]!,
      'tool': instance.tool,
      'at': const NullableTimestampConverter().toJson(instance.at),
    };

const _$AssistantViaEnumMap = {
  AssistantVia.claude: 'claude',
  AssistantVia.chatgpt: 'chatgpt',
  AssistantVia.assistant: 'assistant',
};
