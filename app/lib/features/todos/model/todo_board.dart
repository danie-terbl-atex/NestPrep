import '../../../shared/time/calendar_date.dart';
import 'occurrence_selector.dart';
import 'routine.dart';
import 'task_occurrence.dart';

/// The todo screen's two views over one set of occurrences (todos ADR-0001),
/// derived once per emission rather than in a build method (`FE-12`).
class TodoBoard {
  const TodoBoard({
    required this.today,
    required this.mine,
    required this.everyone,
    required this.routines,
  });

  factory TodoBoard.from({
    required List<TaskOccurrence> occurrences,
    required List<Routine> routines,
    required String memberId,
    required CalendarDate today,
  }) => TodoBoard(
    today: today,
    mine: mineToday(occurrences: occurrences, memberId: memberId, today: today),
    everyone: occurrences,
    routines: routines,
  );

  final CalendarDate today;

  /// Due today or overdue, for me or for anyone, and not yet done.
  final List<TaskOccurrence> mine;

  /// Everything in the window, done or not.
  final List<TaskOccurrence> everyone;

  final List<Routine> routines;

  bool get hasNothingAtAll => everyone.isEmpty && routines.isEmpty;

  /// Everyone's, filtered to one member when the screen asks.
  List<TaskOccurrence> everyoneFor(String? memberId) => memberId == null
      ? everyone
      : [
          for (final occurrence in everyone)
            if (occurrence.isFor(memberId)) occurrence,
        ];
}
