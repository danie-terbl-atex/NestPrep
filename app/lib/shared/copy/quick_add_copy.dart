import '../../features/calendar/model/quick_add/quick_add_result.dart';
import '../recurrence/recurrence_rule.dart';
import 'app_copy.dart';

/// Every word quick add says (`FE-19`, calendar ADR-0004), beside `AppCopy`
/// rather than inside it for the same reason as `CalendarSyncCopy`.
abstract final class QuickAddCopy {
  static const label = 'Quick add';
  static const hint = 'Soccer Tuesdays at 5';
  static const add = 'Add';
  static const edit = 'Edit';
  static const fieldLabel = 'What is happening, and when?';
  static const previewLabel = 'What will be added';

  /// Nothing typed yet: what the bar understands, as an example.
  static const prompt =
      'Try “Dentist 3 March 10:30 for Mia” or “Swimming every '
      'other Thursday 4pm”.';

  static String problem(QuickAddProblem problem) => switch (problem) {
    QuickAddProblem.empty => prompt,
    QuickAddProblem.noTitle =>
      'Say what it is too, like “Swimming Thursdays at 4”.',
    QuickAddProblem.noWhen => 'Say when: a day, a time, or “every Tuesday”.',
    QuickAddProblem.impossibleDate => 'That day is not on the calendar.',
    QuickAddProblem.impossibleTime => 'That time is not on a clock.',
    QuickAddProblem.endsBeforeStart => 'That repeat ends before it starts.',
  };

  /// How the proposal repeats, in one line. Unlike the shorter summary a
  /// routine shows, it keeps "every 2 weeks", because that is exactly what a
  /// member needs to check before adding.
  static String repeats(RecurrenceRule rule) {
    if (rule.frequency == RecurrenceFrequency.weekly &&
        rule.weekdays.isNotEmpty) {
      final days = rule.weekdays.map(AppCopy.weekdayName).join(', ');
      return rule.interval == 1
          ? '${AppCopy.repeatEveryLabel} $days'
          : '${AppCopy.repeatEveryLabel} ${rule.interval} weeks on $days';
    }
    if (rule.frequency == RecurrenceFrequency.monthly && rule.interval == 12) {
      return 'Every year';
    }
    return AppCopy.recurrenceSummary(rule);
  }

  static String until(String date) =>
      '${AppCopy.repeatUntilLabel.toLowerCase()} $date';
}
