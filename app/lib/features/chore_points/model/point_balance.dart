import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/firestore/nullable_timestamp_converter.dart';
import '../../../shared/recurrence/calendar_date_converter.dart';
import '../../../shared/time/calendar_date.dart';

part 'point_balance.freezed.dart';
part 'point_balance.g.dart';

/// A child's stars, at `households/{id}/pointBalances/{memberId}` (todos
/// ADR-0003). Written only by Functions, in the same transaction as the
/// ledger line that moved it; the app reads it and never writes it.
@freezed
abstract class PointBalance with _$PointBalance {
  const factory PointBalance({
    /// The kid profile these stars belong to — also the document id.
    @JsonKey(includeToJson: false) required String id,
    @Default(0) int balance,

    /// Every star ever earned, net of chores unticked.
    @Default(0) int earned,

    /// Every star spent on rewards, net of rewards declined.
    @Default(0) int spent,
    @Default(0) int streakDays,
    @Default(0) int bestStreak,

    /// The last day stars landed, in the household's zone.
    @NullableCalendarDateConverter() CalendarDate? streakLastDay,
    @NullableTimestampConverter() DateTime? updatedAt,
  }) = _PointBalance;

  const PointBalance._();

  factory PointBalance.fromJson(Map<String, Object?> json) =>
      _$PointBalanceFromJson(json);

  /// A child nobody has paid yet: nothing, which is not an error.
  factory PointBalance.none(String memberId) => PointBalance(id: memberId);

  /// The streak as it stands [today]: alive while the last starred day is
  /// today or yesterday, and nothing once a day has been missed.
  int streakOn(CalendarDate today) {
    final last = streakLastDay;
    if (last == null) return 0;
    return last == today || last == today.addDays(-1) ? streakDays : 0;
  }
}
