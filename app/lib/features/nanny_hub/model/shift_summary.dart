import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/firestore/nullable_timestamp_converter.dart';
import 'checklist_progress.dart';
import 'handover_kind.dart';
import 'summary_moment.dart';

part 'shift_summary.freezed.dart';
part 'shift_summary.g.dart';

/// What the parents read when a shift ends, at
/// `households/{id}/nannyShiftSummaries/{shiftId}` — written by
/// `endNannyShift` only, from what the carer logged, in the same transaction
/// that ends the shift (nanny-hub ADR-0002). The app reads it and never
/// writes it.
///
/// Delivery to the parents' phones is the notifications feature's: it picks
/// up a summary whose `delivery.state` is `pending` (the contract is in the
/// nanny-hub overview). The app shows the summary in the hub regardless.
@freezed
abstract class ShiftSummary with _$ShiftSummary {
  const factory ShiftSummary({
    @JsonKey(includeToJson: false) required String id,
    required String carerMemberId,
    @NullableTimestampConverter() DateTime? startedAt,
    @NullableTimestampConverter() DateTime? endedAt,
    String? endedBy,
    @Default(<String, int>{}) Map<String, int> counts,
    @Default(<SummaryMoment>[]) List<SummaryMoment> moments,
    @Default(false) bool isTrimmed,
    @Default(0) int entryCount,
    @Default(0) int photoCount,
    @Default(<String>[]) List<String> childIds,
    @Default(ChecklistProgress()) ChecklistProgress checklist,
    String? closingNote,
  }) = _ShiftSummary;

  const ShiftSummary._();

  factory ShiftSummary.fromJson(Map<String, Object?> json) =>
      _$ShiftSummaryFromJson(json);

  /// The shift the summary is of — the document id.
  String get shiftId => id;

  int countOf(HandoverKind kind) => counts[kind.name] ?? 0;

  /// The kinds that happened, in the order of the buttons, for the line of
  /// tags at the top of a summary.
  List<HandoverKind> get kindsLogged => [
    for (final kind in HandoverKind.values)
      if (countOf(kind) > 0) kind,
  ];

  bool get hadIncident => countOf(HandoverKind.incident) > 0;
}
