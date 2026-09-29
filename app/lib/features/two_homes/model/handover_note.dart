import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/firestore/server_timestamp_converter.dart';
import '../../../shared/recurrence/calendar_date_converter.dart';
import '../../../shared/time/calendar_date.dart';
import 'custody_side.dart';

part 'handover_note.freezed.dart';
part 'handover_note.g.dart';

/// One thing in the bag, and whether it went in.
@freezed
abstract class HandoverItem with _$HandoverItem {
  const factory HandoverItem({required String text, required bool packed}) =
      _HandoverItem;

  factory HandoverItem.fromJson(Map<String, Object?> json) =>
      _$HandoverItemFromJson(json);

  static const maxLength = 80;
}

/// One handover, written up for both homes, at
/// `households/{id}/coParentLinks/{linkId}/handovers/{YYYY-MM-DD}` (household
/// ADR-0004): what is in the bag, medicine given, homework, clothes and
/// anything else. The same record sits in both homes; it says which home
/// saved it last, never which person.
@freezed
abstract class HandoverNote with _$HandoverNote {
  const factory HandoverNote({
    @JsonKey(includeToJson: false) required String id,
    @CalendarDateConverter() required CalendarDate date,
    @Default(<HandoverItem>[]) List<HandoverItem> items,
    String? medicine,
    String? homework,
    String? clothes,
    String? note,
    @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)
    CustodySide? updatedBySide,
    @ServerTimestampConverter() DateTime? updatedAt,
  }) = _HandoverNote;

  const HandoverNote._();

  factory HandoverNote.fromJson(Map<String, Object?> json) =>
      _$HandoverNoteFromJson(json);

  static const maxItems = 30;
  static const maxNoteLength = 300;
  static const maxOtherLength = 500;

  int get packedCount => items.where((item) => item.packed).length;

  bool get hasNotes =>
      [medicine, homework, clothes, note].any((text) => text != null);
}
