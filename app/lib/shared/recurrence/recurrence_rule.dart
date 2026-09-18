import 'package:freezed_annotation/freezed_annotation.dart';

import '../time/calendar_date.dart';
import 'calendar_date_converter.dart';

part 'recurrence_rule.freezed.dart';
part 'recurrence_rule.g.dart';

/// How often a thing repeats. Deliberately a strict subset of RFC 5545 so the
/// stored shape can grow into an RRULE later without a migration (foundation
/// ADR-0005).
enum RecurrenceFrequency { daily, weekly, monthly }

/// Monday is 1 and Sunday is 7, matching `DateTime.weekday` and ISO-8601.
abstract final class Weekday {
  static const monday = 1;
  static const sunday = 7;

  static bool isValid(int value) => value >= monday && value <= sunday;
}

/// The rule half of a recurring event or todo. The other half is the thing's
/// first occurrence, which lives on the thing itself — a rule alone does not
/// know when it starts (foundation ADR-0005).
@freezed
abstract class RecurrenceRule with _$RecurrenceRule {
  const factory RecurrenceRule({
    required RecurrenceFrequency frequency,

    /// Every nth day, week or month. One means every one.
    @Default(1) int interval,

    /// Which days a weekly rule lands on, as ISO weekdays. Empty means "the
    /// same weekday the first occurrence fell on", which is what a member who
    /// never opened the weekday picker meant.
    @Default(<int>[]) List<int> weekdays,

    /// The last day an occurrence may fall on, inclusive. Null repeats forever.
    @NullableCalendarDateConverter() CalendarDate? until,
  }) = _RecurrenceRule;

  const RecurrenceRule._();

  factory RecurrenceRule.fromJson(Map<String, Object?> json) =>
      _$RecurrenceRuleFromJson(json);

  /// Whether this rule is one the expansion can run. A rule that fails this is
  /// a document written by a build that knew something this one does not, or a
  /// document that was never valid; either way the caller treats the thing as
  /// happening once (`BE-10`).
  bool get isExpandable =>
      interval >= 1 &&
      interval <= maxInterval &&
      weekdays.every(Weekday.isValid) &&
      (frequency != RecurrenceFrequency.weekly || weekdays.length <= 7);

  /// The same rule, repeating forever. `copyWith` cannot put a null back into
  /// a nullable field, so clearing an end date needs a name of its own.
  RecurrenceRule withNoEnd() => RecurrenceRule(
    frequency: frequency,
    interval: interval,
    weekdays: weekdays,
  );

  /// An interval nobody means, and past which expansion is pointless work.
  static const maxInterval = 366;
}
