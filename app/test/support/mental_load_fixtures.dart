import 'package:nestprep/design/tokens/nest_member_palette.dart';
import 'package:nestprep/features/calendar/model/household_event.dart';
import 'package:nestprep/features/groceries/model/grocery_item.dart';
import 'package:nestprep/features/household/model/member.dart';
import 'package:nestprep/features/todos/model/task.dart';
import 'package:nestprep/features/todos/model/task_completion.dart';
import 'package:nestprep/shared/time/calendar_date.dart';

import 'household_fixtures.dart';

/// A household of two parents — Sam and Alex — a helper and a kid, and a
/// week's worth of what they did, for the mental-load view (calendar
/// ADR-0006). The week is Monday 28 September 2026.
abstract final class LoadFixtures {
  static final weekStart = CalendarDate(2026, 9, 28);
  static final wednesday = CalendarDate(2026, 9, 30);

  static const alexMemberId = 'm-alex';

  static Member get alex => const Member(
    id: alexMemberId,
    displayName: 'Alex Parent',
    color: MemberColor.coral,
    roleName: 'parent',
    claimedBy: 'uid-alex',
  );

  static List<Member> get members => [
    Fixtures.sam,
    alex,
    Fixtures.thandi,
    Fixtures.kid,
  ];

  /// Noon UTC on [day] — the same day in Johannesburg.
  static DateTime at(CalendarDate day) =>
      DateTime.utc(day.year, day.month, day.day, 12);

  static CalendarDate dayOf(DateTime instant) =>
      CalendarDate.fromDateTime(instant.toUtc());

  static HouseholdEvent event(
    String id, {
    required String createdBy,
    CalendarDate? date,
    List<String> memberIds = const [],
  }) => HouseholdEvent(
    id: id,
    title: 'Event $id',
    date: date ?? wednesday,
    startMinute: 9 * 60,
    memberIds: memberIds,
    createdBy: createdBy,
  );

  static Task task(String id, {List<String> assigneeIds = const []}) => Task(
    id: id,
    title: 'Task $id',
    dueDate: wednesday,
    assigneeIds: assigneeIds,
    createdBy: Fixtures.samMemberId,
  );

  static TaskCompletion done(String taskId, {required String by}) =>
      TaskCompletion(
        id: TaskCompletion.idFor(taskId, wednesday),
        taskId: taskId,
        occurrenceDate: wednesday,
        completedBy: by,
        completedFor: by,
      );

  static GroceryItem grocery(
    String id, {
    required String addedBy,
    DateTime? addedAt,
    String? boughtBy,
    DateTime? boughtAt,
  }) => GroceryItem(
    id: id,
    name: 'Item $id',
    addedBy: addedBy,
    addedAt: addedAt,
    boughtBy: boughtBy,
    boughtAt: boughtAt,
  );
}
