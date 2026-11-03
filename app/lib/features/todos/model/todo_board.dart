import '../../../shared/time/calendar_date.dart';
import 'kid_chores.dart';
import 'occurrence_selector.dart';
import 'routine.dart';
import 'task_occurrence.dart';

/// The todo screen's lenses over one set of occurrences (todos ADR-0001),
/// derived once per emission rather than in a build method (`FE-12`).
class TodoBoard {
  const TodoBoard({
    required this.today,
    required this.mine,
    required this.everyone,
    required this.routines,
    this.justDone = const [],
    this.kidIds = const {},
    this.chores = const [],
  });

  factory TodoBoard.from({
    required List<TaskOccurrence> occurrences,
    required List<Routine> routines,
    required String memberId,
    required CalendarDate today,
    required DateTime now,
    List<String> kidIds = const [],
  }) {
    final kids = kidIds.toSet();
    return TodoBoard(
      today: today,
      mine: mineToday(
        occurrences: occurrences,
        memberId: memberId,
        today: today,
      ),
      justDone: doneRecently(
        occurrences: occurrences,
        memberId: memberId,
        since: now.subtract(justDoneWindow),
      ),
      everyone: [
        for (final occurrence in occurrences)
          if (!isChore(occurrence, kids)) occurrence,
      ],
      routines: routines,
      kidIds: kids,
      chores: [
        for (final kidId in kidIds)
          KidChores.from(kidId: kidId, occurrences: occurrences, today: today),
      ],
    );
  }

  final CalendarDate today;

  /// Due today or overdue, for me or for anyone, and not yet done.
  final List<TaskOccurrence> mine;

  final List<TaskOccurrence> justDone;

  /// Everything in the window that is not a chore, done or not.
  final List<TaskOccurrence> everyone;

  final List<Routine> routines;

  final Set<String> kidIds;

  final List<KidChores> chores;

  bool get hasKids => kidIds.isNotEmpty;

  int get openChoreCount => {
    for (final kid in chores)
      for (final chore in kid.chores)
        if (!chore.isDone) chore.key,
  }.length;

  /// Everyone's, filtered to one member when the screen asks.
  List<TaskOccurrence> everyoneFor(String? memberId) => memberId == null
      ? everyone
      : [
          for (final occurrence in everyone)
            if (occurrence.isFor(memberId)) occurrence,
        ];
}
