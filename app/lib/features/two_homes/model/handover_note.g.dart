// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'handover_note.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_HandoverItem _$HandoverItemFromJson(Map<String, dynamic> json) =>
    _HandoverItem(text: json['text'] as String, packed: json['packed'] as bool);

Map<String, dynamic> _$HandoverItemToJson(_HandoverItem instance) =>
    <String, dynamic>{'text': instance.text, 'packed': instance.packed};

_HandoverNote _$HandoverNoteFromJson(Map<String, dynamic> json) =>
    _HandoverNote(
      id: json['id'] as String,
      date: const CalendarDateConverter().fromJson(json['date']),
      items:
          (json['items'] as List<dynamic>?)
              ?.map((e) => HandoverItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <HandoverItem>[],
      medicine: json['medicine'] as String?,
      homework: json['homework'] as String?,
      clothes: json['clothes'] as String?,
      note: json['note'] as String?,
      updatedBySide: $enumDecodeNullable(
        _$CustodySideEnumMap,
        json['updatedBySide'],
        unknownValue: JsonKey.nullForUndefinedEnumValue,
      ),
      updatedAt: const ServerTimestampConverter().fromJson(json['updatedAt']),
    );

Map<String, dynamic> _$HandoverNoteToJson(_HandoverNote instance) =>
    <String, dynamic>{
      'date': const CalendarDateConverter().toJson(instance.date),
      'items': instance.items.map((e) => e.toJson()).toList(),
      'medicine': instance.medicine,
      'homework': instance.homework,
      'clothes': instance.clothes,
      'note': instance.note,
      'updatedBySide': _$CustodySideEnumMap[instance.updatedBySide],
      'updatedAt': const ServerTimestampConverter().toJson(instance.updatedAt),
    };

const _$CustodySideEnumMap = {CustodySide.a: 'a', CustodySide.b: 'b'};
