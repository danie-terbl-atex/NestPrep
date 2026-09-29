import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/firestore/nullable_timestamp_converter.dart';

part 'point_entry.freezed.dart';
part 'point_entry.g.dart';

/// Why a child's stars moved (todos ADR-0003).
enum EntryKind { chore, choreUndone, reward, rewardReturned }

/// One line of a child's ledger, at `households/{id}/pointEntries/{id}`.
/// Append-only and written only by Functions; the balance is the sum of these.
@freezed
abstract class PointEntry with _$PointEntry {
  const factory PointEntry({
    @JsonKey(includeToJson: false) required String id,
    required String memberId,

    /// Positive when stars were earned or returned, negative when spent or
    /// taken back.
    required int delta,
    @JsonKey(unknownEnumValue: EntryKind.chore) required EntryKind kind,

    /// The completion or reward request the line is about.
    required String sourceId,
    required String title,
    @NullableTimestampConverter() DateTime? at,
  }) = _PointEntry;

  const PointEntry._();

  factory PointEntry.fromJson(Map<String, Object?> json) =>
      _$PointEntryFromJson(json);
}
