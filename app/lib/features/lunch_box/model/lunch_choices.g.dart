// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lunch_choices.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LunchChoices _$LunchChoicesFromJson(Map<String, dynamic> json) =>
    _LunchChoices(
      id: json['id'] as String,
      childId: json['childId'] as String,
      week: json['week'] as String,
      options:
          (json['options'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(
              k,
              (e as List<dynamic>)
                  .map((e) => LunchPick.fromJson(e as Map<String, dynamic>))
                  .toList(),
            ),
          ) ??
          const <String, List<LunchPick>>{},
      chosen:
          (json['chosen'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const <String, String>{},
      editedDay: json['editedDay'] as String?,
      chosenKey: json['chosenKey'] as String?,
      updatedBy: json['updatedBy'] as String,
      updatedAt: const ServerTimestampConverter().fromJson(json['updatedAt']),
    );

Map<String, dynamic> _$LunchChoicesToJson(_LunchChoices instance) =>
    <String, dynamic>{
      'childId': instance.childId,
      'week': instance.week,
      'options': instance.options.map(
        (k, e) => MapEntry(k, e.map((e) => e.toJson()).toList()),
      ),
      'chosen': instance.chosen,
      'editedDay': instance.editedDay,
      'chosenKey': instance.chosenKey,
      'updatedBy': instance.updatedBy,
      'updatedAt': const ServerTimestampConverter().toJson(instance.updatedAt),
    };
