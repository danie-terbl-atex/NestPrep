import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nestprep/design/tokens/nest_member_palette.dart';
import 'package:nestprep/features/accounts/model/account.dart';
import 'package:nestprep/features/calendar/model/event_exception.dart';
import 'package:nestprep/features/calendar/model/household_event.dart';
import 'package:nestprep/features/documents/model/document_folder.dart';
import 'package:nestprep/features/documents/model/household_document.dart';
import 'package:nestprep/features/groceries/model/grocery_item.dart';
import 'package:nestprep/features/household/model/birthday.dart';
import 'package:nestprep/features/household/model/household.dart';
import 'package:nestprep/features/household/model/member.dart';
import 'package:nestprep/features/live_location/model/coordinates.dart';
import 'package:nestprep/features/live_location/model/member_location.dart';
import 'package:nestprep/features/meal_planning/model/meal.dart';
import 'package:nestprep/features/meal_planning/model/week_plan.dart';
import 'package:nestprep/features/todos/model/routine.dart';
import 'package:nestprep/features/todos/model/task.dart';
import 'package:nestprep/features/todos/model/task_completion.dart';
import 'package:nestprep/shared/recurrence/recurrence_rule.dart';
import 'package:nestprep/shared/time/calendar_date.dart';

/// Every stored model, once, with every field populated — the fixtures two
/// boundary tests share (`ENG-01`): that each model round-trips through its
/// converters, and that what it writes is something Firestore can store.
///
/// Every optional field is filled and every timestamp is non-null, because
/// `ServerTimestampConverter` writes a `FieldValue.serverTimestamp()` sentinel
/// for null which by design does not round-trip. A field left out here is a
/// field neither test is looking at.
final class ModelFixture {
  const ModelFixture({
    required this.label,
    required this.id,
    required this.keys,
    required this.value,
    required this.toJson,
    required this.fromJson,
    this.note,
  });

  final String label;

  /// The document id, which arrives under `id` on a read and is never stored.
  final String id;

  /// Exactly the keys this model writes. Written out rather than derived, so
  /// adding a field without deciding whether it is stored fails loudly.
  final Set<String> keys;

  final Object value;
  final Map<String, Object?> Function() toJson;
  final Object Function(Map<String, Object?> json) fromJson;

  /// Why a key is worth naming, where it is not obvious.
  final String? note;
}

/// The instant every fixture's timestamps carry, in UTC because that is what
/// the converters read a `Timestamp` back as.
final fixtureInstant = DateTime.utc(2026, 9, 18, 6, 30);

/// The rule the three recurring models nest. Weekly on Tuesday and Thursday,
/// every second week, ending in March — every field of it populated.
final fixtureRecurrence = RecurrenceRule(
  frequency: RecurrenceFrequency.weekly,
  interval: 2,
  weekdays: const [2, 4], // Tuesday and Thursday, as ISO weekdays
  until: CalendarDate(2027, 3, 31),
);

List<ModelFixture> modelFixtures() {
  final at = fixtureInstant;

  final account = Account(
    id: 'acct',
    displayName: 'Daniel',
    photoUrl: 'https://example.invalid/d.png',
    householdIds: const ['h1', 'h2'],
    activeHouseholdId: 'h1',
    createdAt: at,
    lastSignedInAt: at,
  );
  final household = Household(
    id: 'h1',
    name: 'Snyman',
    timeZone: 'Africa/Johannesburg',
    members: const {'uidA': 'admin', 'uidB': 'member'},
    createdBy: 'uidA',
    createdAt: at,
  );
  final member = Member(
    id: 'm1',
    displayName: 'Ada',
    color: MemberColor.teal,
    roleName: 'admin',
    // With a year, because the year-less shape is the one a round trip could
    // quietly lose; `birthday_test.dart` covers `--MM-DD` on its own.
    birthday: Birthday(year: 1985, month: 12, day: 10),
    claimedBy: 'uidA',
    createdAt: at,
  );
  final item = GroceryItem(
    id: 'g1',
    name: 'Milk',
    quantity: '2 l',
    addedBy: 'm1',
    addedAt: at,
    boughtAt: at,
    boughtBy: 'm2',
  );
  final event = HouseholdEvent(
    id: 'e1',
    title: 'School run',
    note: 'back gate',
    date: CalendarDate(2026, 9, 21),
    startMinute: 7 * 60 + 15,
    endMinute: 8 * 60,
    recurrence: fixtureRecurrence,
    memberIds: const ['m1', 'm2'],
    createdBy: 'm1',
    createdAt: at,
  );
  final exception = EventException(
    id: 'x1',
    eventId: 'e1',
    occurrenceDate: CalendarDate(2026, 9, 28),
    skippedBy: 'm1',
    skippedAt: at,
  );
  final task = Task(
    id: 't1',
    title: 'Bins',
    note: 'green one',
    dueDate: CalendarDate(2026, 9, 19),
    recurrence: fixtureRecurrence,
    assigneeIds: const ['m2'],
    createdBy: 'm1',
    routineId: 'r1',
    createdAt: at,
  );
  final routine = Routine(
    id: 'r1',
    name: 'Laundry',
    firstDate: CalendarDate(2026, 9, 19),
    recurrence: fixtureRecurrence,
    defaultAssigneeIds: const ['m1', 'm2'],
    color: MemberColor.teal, // not the default, so a round trip proves it
    createdBy: 'm1',
    createdAt: at,
  );
  final completion = TaskCompletion(
    id: 'c1',
    taskId: 't1',
    occurrenceDate: CalendarDate(2026, 9, 19),
    completedBy: 'm1',
    completedFor: 'm2',
    completedAt: at,
  );
  final meal = Meal(
    id: 'ml1',
    name: 'Spag bol',
    nameKey: 'spag bol',
    addedBy: 'm1',
    createdAt: at,
  );
  const plan = WeekPlan(id: '2026-09-21', slots: {'2026-09-21-dinner': 'ml1'});
  final location = MemberLocation(
    id: 'm1',
    point: const Coordinates(latitude: -26.2041, longitude: 28.0473),
    accuracyMetres: 12,
    reportedAt: at,
    sharingUntil: at.add(const Duration(hours: 1)),
  );
  final folder = DocumentFolder(
    id: 'f1',
    name: 'School',
    createdBy: 'm1',
    createdAt: at,
  );
  final document = HouseholdDocument(
    id: 'd1',
    folderId: 'f1',
    name: 'Term letter',
    contentType: 'application/pdf',
    sizeBytes: 120000,
    uploadedBy: 'm1',
    uploadedAt: at,
  );

  return [
    ModelFixture(
      label: 'Account',
      id: 'acct',
      value: account,
      toJson: account.toJson,
      fromJson: Account.fromJson,
      keys: const {
        'displayName',
        'photoUrl',
        'householdIds',
        'activeHouseholdId',
        'createdAt',
        'lastSignedInAt',
      },
    ),
    ModelFixture(
      label: 'Household',
      id: 'h1',
      value: household,
      toJson: household.toJson,
      fromJson: Household.fromJson,
      keys: const {'name', 'timeZone', 'members', 'createdBy', 'createdAt'},
      note:
          '`members` is the uid→role map every Security Rule reads and only a '
          'Cloud Function writes (foundation ADR-0002). Rename it and every '
          'rule in the project denies everything.',
    ),
    ModelFixture(
      label: 'Member',
      id: 'm1',
      value: member,
      toJson: member.toJson,
      fromJson: Member.fromJson,
      keys: const {
        'displayName',
        'color',
        'role',
        'birthday',
        'access',
        'claimedBy',
        'createdAt',
      },
      note:
          '`roleName` is stored as `role`, which is the name the rules read. '
          '`birthday` is a string in one of two shapes, never a nested model '
          '(birthdays ADR-0001). `access` is a map of area to level, or null '
          '(household ADR-0003).',
    ),
    ModelFixture(
      label: 'GroceryItem',
      id: 'g1',
      value: item,
      toJson: item.toJson,
      fromJson: GroceryItem.fromJson,
      keys: const {
        'name',
        'quantity',
        'addedBy',
        'addedAt',
        'boughtAt',
        'boughtBy',
      },
    ),
    ModelFixture(
      label: 'HouseholdEvent',
      id: 'e1',
      value: event,
      toJson: event.toJson,
      fromJson: HouseholdEvent.fromJson,
      keys: const {
        'title',
        'note',
        'date',
        'startMinute',
        'endMinute',
        'recurrence',
        'memberIds',
        'createdBy',
        'createdAt',
      },
    ),
    ModelFixture(
      label: 'EventException',
      id: 'x1',
      value: exception,
      toJson: exception.toJson,
      fromJson: EventException.fromJson,
      keys: const {'eventId', 'occurrenceDate', 'skippedBy', 'skippedAt'},
    ),
    ModelFixture(
      label: 'Task',
      id: 't1',
      value: task,
      toJson: task.toJson,
      fromJson: Task.fromJson,
      keys: const {
        'title',
        'note',
        'dueDate',
        'recurrence',
        'assigneeIds',
        'createdBy',
        'routineId',
        'createdAt',
      },
    ),
    ModelFixture(
      label: 'Routine',
      id: 'r1',
      value: routine,
      toJson: routine.toJson,
      fromJson: Routine.fromJson,
      keys: const {
        'name',
        'firstDate',
        'recurrence',
        'defaultAssigneeIds',
        'color',
        'createdBy',
        'createdAt',
      },
    ),
    ModelFixture(
      label: 'TaskCompletion',
      id: 'c1',
      value: completion,
      toJson: completion.toJson,
      fromJson: TaskCompletion.fromJson,
      keys: const {
        'taskId',
        'occurrenceDate',
        'completedBy',
        'completedFor',
        'completedAt',
      },
    ),
    ModelFixture(
      label: 'Meal',
      id: 'ml1',
      value: meal,
      toJson: meal.toJson,
      fromJson: Meal.fromJson,
      keys: const {'name', 'nameKey', 'addedBy', 'createdAt'},
      note:
          '`nameKey` is what the "have we typed this before" query reads; it '
          'is derived from `name` and never typed.',
    ),
    ModelFixture(
      label: 'MemberLocation',
      id: 'm1',
      value: location,
      toJson: location.toJson,
      fromJson: MemberLocation.fromJson,
      keys: const {'point', 'accuracyMetres', 'reportedAt', 'sharingUntil'},
      note:
          'the document id is the member id, which is what makes the rule '
          '`isOwnMember` on the path and not on a field — rename the key and '
          'anybody could write anybody"s position (live-location ADR-0001).',
    ),
    ModelFixture(
      label: 'WeekPlan',
      id: '2026-09-21',
      value: plan,
      toJson: plan.toJson,
      fromJson: WeekPlan.fromJson,
      keys: const {'slots'},
    ),
    ModelFixture(
      label: 'DocumentFolder',
      id: 'f1',
      value: folder,
      toJson: folder.toJson,
      fromJson: DocumentFolder.fromJson,
      keys: const {'name', 'createdBy', 'createdAt'},
    ),
    ModelFixture(
      label: 'HouseholdDocument',
      id: 'd1',
      value: document,
      toJson: document.toJson,
      fromJson: HouseholdDocument.fromJson,
      keys: const {
        'folderId',
        'name',
        'contentType',
        'sizeBytes',
        'uploadedBy',
        'uploadedAt',
      },
      note:
          'the document id is also the name of its Cloud Storage object, so a '
          'row and its bytes are found from each other (documents ADR-0001).',
    ),
  ];
}

/// A `Timestamp` of [fixtureInstant], for a test that wants to assert the
/// stored form rather than the model.
Timestamp get fixtureTimestamp => Timestamp.fromDate(fixtureInstant);
