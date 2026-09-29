// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inbox_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DigestLine _$DigestLineFromJson(Map<String, dynamic> json) => _DigestLine(
  text: json['text'] as String,
  detail: json['detail'] as String?,
);

Map<String, dynamic> _$DigestLineToJson(_DigestLine instance) =>
    <String, dynamic>{'text': instance.text, 'detail': instance.detail};

_DigestSection _$DigestSectionFromJson(Map<String, dynamic> json) =>
    _DigestSection(
      kind: json['kind'] as String,
      total: (json['total'] as num?)?.toInt() ?? 0,
      items:
          (json['items'] as List<dynamic>?)
              ?.map((e) => DigestLine.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <DigestLine>[],
    );

Map<String, dynamic> _$DigestSectionToJson(_DigestSection instance) =>
    <String, dynamic>{
      'kind': instance.kind,
      'total': instance.total,
      'items': instance.items.map((e) => e.toJson()).toList(),
    };

_InboxTarget _$InboxTargetFromJson(Map<String, dynamic> json) =>
    _InboxTarget(kind: json['kind'] as String, id: json['id'] as String?);

Map<String, dynamic> _$InboxTargetToJson(_InboxTarget instance) =>
    <String, dynamic>{'kind': instance.kind, 'id': instance.id};

_InboxItem _$InboxItemFromJson(Map<String, dynamic> json) => _InboxItem(
  id: json['id'] as String,
  memberId: json['memberId'] as String,
  category: json['category'] as String,
  title: json['title'] as String,
  body: json['body'] as String,
  detail: json['detail'] as String?,
  sections:
      (json['sections'] as List<dynamic>?)
          ?.map((e) => DigestSection.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <DigestSection>[],
  target: json['target'] == null
      ? const InboxTarget(kind: 'inboxItem')
      : InboxTarget.fromJson(json['target'] as Map<String, dynamic>),
  localDate: json['localDate'] as String? ?? '',
  createdAt: const NullableTimestampConverter().fromJson(json['createdAt']),
  readAt: const NullableTimestampConverter().fromJson(json['readAt']),
);

Map<String, dynamic> _$InboxItemToJson(
  _InboxItem instance,
) => <String, dynamic>{
  'memberId': instance.memberId,
  'category': instance.category,
  'title': instance.title,
  'body': instance.body,
  'detail': instance.detail,
  'sections': instance.sections.map((e) => e.toJson()).toList(),
  'target': instance.target.toJson(),
  'localDate': instance.localDate,
  'createdAt': const NullableTimestampConverter().toJson(instance.createdAt),
  'readAt': const NullableTimestampConverter().toJson(instance.readAt),
};
