import '../../../shared/time/calendar_date.dart';
import 'task_occurrence.dart';

class KidChores {
  const KidChores({required this.kidId, required this.chores});

  factory KidChores.from({
    required String kidId,
    required List<TaskOccurrence> occurrences,
    required CalendarDate today,
  }) {
    final mine = [
      for (final occurrence in occurrences)
        if (occurrence.assigneeIds.contains(kidId) &&
            (occurrence.date == today || occurrence.isOverdue(today)))
          occurrence,
    ];
    return KidChores(
      kidId: kidId,
      chores: [
        ...mine.where((chore) => chore.isOverdue(today)),
        ...mine.where((chore) => chore.date == today && !chore.isDone),
        ...mine.where((chore) => chore.isDone),
      ],
    );
  }

  final String kidId;
  final List<TaskOccurrence> chores;

  int get doneCount => chores.where((chore) => chore.isDone).length;

  bool get carriesStars => chores.any((chore) => chore.task.carriesStars);

  int get starsToday => chores
      .where((chore) => chore.isDone)
      .fold(0, (sum, chore) => sum + chore.task.points);

  bool isLastOpen(TaskOccurrence chore) => isLastOpenOf(chores, chore);
}

bool isLastOpenOf(List<TaskOccurrence> chores, TaskOccurrence chore) =>
    !chore.isDone &&
    chores.every((other) => other.isDone || other.key == chore.key);

bool isKidsOnly(TaskOccurrence occurrence, Set<String> kidIds) =>
    occurrence.assigneeIds.isNotEmpty &&
    occurrence.assigneeIds.every(kidIds.contains);
