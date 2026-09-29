import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../design/tokens/nest_member_palette.dart';

import '../../../shared/failure/firebase_failure_mapper.dart';
import '../../../shared/firestore/typed_collection.dart';
import '../../../shared/recurrence/recurrence_rule.dart';
import '../../../shared/time/calendar_date.dart';
import '../model/routine.dart';
import '../model/task.dart';
import '../model/task_completion.dart';
import 'todo_repository.dart';

final class FirestoreTodoRepository implements TodoRepository {
  FirestoreTodoRepository(this._firestore);

  static const householdsPath = 'households';
  static const tasksPath = 'tasks';
  static const routinesPath = 'routines';
  static const completionsPath = 'taskCompletions';

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _household(String householdId) =>
      _firestore.collection(householdsPath).doc(householdId);

  CollectionReference<Task> _tasks(String householdId) => typedCollection(
    _household(householdId).collection(tasksPath),
    fromJson: Task.fromJson,
    toJson: (task) => task.toJson(),
  );

  CollectionReference<Routine> _routines(String householdId) => typedCollection(
    _household(householdId).collection(routinesPath),
    fromJson: Routine.fromJson,
    toJson: (routine) => routine.toJson(),
  );

  CollectionReference<TaskCompletion> _completions(String householdId) =>
      typedCollection(
        _household(householdId).collection(completionsPath),
        fromJson: TaskCompletion.fromJson,
        toJson: (completion) => completion.toJson(),
      );

  @override
  Stream<List<Task>> watchTasks(String householdId, {String? assignedTo}) =>
      (assignedTo == null
              ? _tasks(householdId)
              : _tasks(householdId)
                    .where('assigneeIds', arrayContains: assignedTo))
          .limit(TodoRepository.taskLimit)
          .snapshots()
          .map((snapshot) => [for (final doc in snapshot.docs) doc.data()])
          .handleError((Object error) => throw failureFromFirebase(error));

  @override
  Stream<List<Routine>> watchRoutines(String householdId) =>
      _routines(householdId)
          .orderBy('name')
          .limit(TodoRepository.taskLimit)
          .snapshots()
          .map((snapshot) => [for (final doc in snapshot.docs) doc.data()])
          .handleError((Object error) => throw failureFromFirebase(error));

  @override
  Stream<List<TaskCompletion>> watchCompletions(
    String householdId, {
    required CalendarDate from,
    required CalendarDate to,
    String? completedFor,
  }) =>
      (completedFor == null
              ? _completions(householdId)
              : _completions(householdId)
                    .where('completedFor', isEqualTo: completedFor))
          // A range on the date string, which sorts the same way the calendar
          // does because the format is YYYY-MM-DD (`ENG-21`).
          .where('occurrenceDate', isGreaterThanOrEqualTo: from.iso)
          .where('occurrenceDate', isLessThanOrEqualTo: to.iso)
          .snapshots()
          .map((snapshot) => [for (final doc in snapshot.docs) doc.data()])
          .handleError((Object error) => throw failureFromFirebase(error));

  @override
  Future<void> saveTask({
    required String householdId,
    String? taskId,
    required String title,
    String? note,
    required CalendarDate dueDate,
    RecurrenceRule? recurrence,
    required List<String> assigneeIds,
    required String createdBy,
    String? routineId,
  }) {
    final tasks = _tasks(householdId);
    if (taskId == null) {
      final document = tasks.doc();
      return _guarded(
        () => document.set(
          Task(
            id: document.id,
            title: title,
            note: note,
            dueDate: dueDate,
            recurrence: recurrence,
            assigneeIds: assigneeIds,
            createdBy: createdBy,
            routineId: routineId,
          ),
        ),
      );
    }
    // An edit never rewrites who made it or when (the rules refuse that too).
    return _guarded(
      () => tasks.doc(taskId).update({
        'title': title,
        'note': note,
        'dueDate': dueDate.iso,
        'recurrence': recurrence?.toJson(),
        'assigneeIds': assigneeIds,
        'routineId': routineId,
      }),
    );
  }

  @override
  Future<void> deleteTask({
    required String householdId,
    required String taskId,
  }) => _guarded(() => _tasks(householdId).doc(taskId).delete());

  @override
  Future<void> complete({
    required String householdId,
    required String taskId,
    required CalendarDate occurrenceDate,
    required String completedBy,
    required String completedFor,
  }) {
    final id = TaskCompletion.idFor(taskId, occurrenceDate);
    return _guarded(
      () => _completions(householdId)
          .doc(id)
          .set(
            TaskCompletion(
              id: id,
              taskId: taskId,
              occurrenceDate: occurrenceDate,
              completedBy: completedBy,
              completedFor: completedFor,
            ),
          ),
    );
  }

  @override
  Future<void> uncomplete({
    required String householdId,
    required String taskId,
    required CalendarDate occurrenceDate,
  }) => _guarded(
    () =>
        _completions(householdId)
            .doc(TaskCompletion.idFor(taskId, occurrenceDate))
            .delete(),
  );

  @override
  Future<void> saveRoutine({
    required String householdId,
    String? routineId,
    required String name,
    required CalendarDate firstDate,
    RecurrenceRule? recurrence,
    required List<String> defaultAssigneeIds,
    required MemberColor color,
    required String createdBy,
  }) {
    final routines = _routines(householdId);
    if (routineId == null) {
      final document = routines.doc();
      return _guarded(
        () => document.set(
          Routine(
            id: document.id,
            name: name,
            firstDate: firstDate,
            recurrence: recurrence,
            defaultAssigneeIds: defaultAssigneeIds,
            color: color,
            createdBy: createdBy,
          ),
        ),
      );
    }
    return _guarded(
      () => routines.doc(routineId).update({
        'name': name,
        'firstDate': firstDate.iso,
        'recurrence': recurrence?.toJson(),
        'defaultAssigneeIds': defaultAssigneeIds,
        'color': color.name,
      }),
    );
  }

  @override
  Future<void> deleteRoutine({
    required String householdId,
    required String routineId,
  }) => _guarded(() => _routines(householdId).doc(routineId).delete());

  Future<void> _guarded(Future<void> Function() write) async {
    try {
      await write();
    } on FirebaseException catch (error) {
      throw failureFromFirebase(error);
    }
  }
}
