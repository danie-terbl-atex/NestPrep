import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/tokens/nest_member_palette.dart';
import 'package:nestprep/features/accounts/model/account.dart';
import 'package:nestprep/features/calendar/model/event_exception.dart';
import 'package:nestprep/features/calendar/model/household_event.dart';
import 'package:nestprep/features/groceries/model/grocery_item.dart';
import 'package:nestprep/features/household/model/birthday.dart';
import 'package:nestprep/features/household/model/member.dart';
import 'package:nestprep/features/live_location/model/coordinates.dart';
import 'package:nestprep/features/live_location/model/member_location.dart';
import 'package:nestprep/features/meal_planning/model/meal.dart';
import 'package:nestprep/features/meal_planning/model/week_plan.dart';
import 'package:nestprep/features/todos/model/routine.dart';
import 'package:nestprep/features/todos/model/task.dart';
import 'package:nestprep/features/todos/model/task_completion.dart';
import 'package:nestprep/shared/time/calendar_date.dart';

/// What a model writes has to be exactly what `firestore.rules` allows, because
/// the rules list every permitted key with `hasOnly` and refuse the write
/// otherwise. Nothing else in the suite compares the two: the rules tests write
/// their own fixtures, and the controller tests stop at a fake repository.
///
/// This is the seam where they meet. It has already earned its place — a
/// grocery item was being written with a server timestamp in `boughtAt`, so
/// every item would have arrived already bought and the rules would have
/// refused the create.
void main() {
  final date = CalendarDate.parse('2026-09-18');

  /// The keys a create writes, and which of them the server fills in.
  ({Set<String> keys, Set<String> serverAssigned, Set<String> nulls}) shapeOf(
    Map<String, Object?> json,
  ) => (
    keys: json.keys.toSet(),
    serverAssigned: {
      for (final entry in json.entries)
        if (entry.value is FieldValue) entry.key,
    },
    nulls: {
      for (final entry in json.entries)
        if (entry.value == null) entry.key,
    },
  );

  group('users/{uid}', () {
    test(
      'writes exactly the keys the rule names, with both times the server"s',
      () {
        final shape = shapeOf(
          const Account(id: 'u', displayName: 'Sam Parent').toJson(),
        );
        expect(shape.keys, {
          'displayName',
          'photoUrl',
          'householdIds',
          'activeHouseholdId',
          'createdAt',
          'lastSignedInAt',
        });
        expect(shape.serverAssigned, {'createdAt', 'lastSignedInAt'});
      },
    );
  });

  group('members/{memberId}', () {
    test('writes an unclaimed profile with the server"s creation time', () {
      final json = const Member(
        id: 'm',
        displayName: 'Thandi',
        color: MemberColor.mint,
        roleName: 'helper',
      ).toJson();
      final shape = shapeOf(json);
      expect(shape.keys, {
        'displayName',
        'color',
        'role',
        'birthday',
        'claimedBy',
        'createdAt',
      });
      expect(shape.serverAssigned, {'createdAt'});
      // The rules refuse a create that claims a profile for somebody.
      expect(json['claimedBy'], isNull);
      expect(json['color'], 'mint');
      expect(
        json['birthday'],
        isNull,
        reason: 'no birthday is what the rule calls an absent one',
      );
    });

    test('writes a birthday as the string the rule matches, not a model', () {
      // Firestore never calls `toJson()`, so a birthday left as an object is a
      // write that fails on a device and nowhere else.
      expect(
        Member(
          id: 'm',
          displayName: 'Thandi',
          color: MemberColor.mint,
          roleName: 'helper',
          birthday: Birthday(year: 1991, month: 3, day: 7),
        ).toJson()['birthday'],
        '1991-03-07',
      );
      expect(
        Member(
          id: 'm',
          displayName: 'Kid',
          color: MemberColor.sky,
          roleName: 'member',
          birthday: Birthday(month: 2, day: 29),
        ).toJson()['birthday'],
        '--02-29',
        reason: 'the year-less shape the rules also accept',
      );
    });
  });

  group('groceryItems/{itemId}', () {
    test('writes an item that is not yet bought', () {
      final json = const GroceryItem(
        id: 'i',
        name: 'Milk',
        addedBy: 'm-sam',
      ).toJson();
      final shape = shapeOf(json);
      expect(shape.keys, {
        'name',
        'quantity',
        'addedBy',
        'addedAt',
        'boughtAt',
        'boughtBy',
      });
      // Only `addedAt` is the server's. `boughtAt` must be null, or the rules
      // refuse the create and every new item arrives bought.
      expect(shape.serverAssigned, {'addedAt'});
      expect(shape.nulls, containsAll({'boughtAt', 'boughtBy'}));
    });
  });

  group('tasks/{taskId}', () {
    test('writes exactly the keys the rule names', () {
      final json = Task(
        id: 't',
        title: 'Bins',
        dueDate: date,
        createdBy: 'm-sam',
      ).toJson();
      final shape = shapeOf(json);
      expect(shape.keys, {
        'title',
        'note',
        'dueDate',
        'recurrence',
        'assigneeIds',
        'createdBy',
        'routineId',
        'createdAt',
      });
      expect(shape.serverAssigned, {'createdAt'});
      expect(json['dueDate'], '2026-09-18');
    });
  });

  group('routines/{routineId}', () {
    test('writes exactly the keys the rule names', () {
      final json = Routine(
        id: 'r',
        name: 'Laundry Day Tasks',
        firstDate: date,
        createdBy: 'm-sam',
      ).toJson();
      final shape = shapeOf(json);
      expect(shape.keys, {
        'name',
        'firstDate',
        'recurrence',
        'defaultAssigneeIds',
        'color',
        'createdBy',
        'createdAt',
      });
      expect(shape.serverAssigned, {'createdAt'});
    });
  });

  group('taskCompletions/{taskId}_{date}', () {
    test('writes the keys the rule names, and an id derived from them', () {
      final completion = TaskCompletion(
        id: TaskCompletion.idFor('t', date),
        taskId: 't',
        occurrenceDate: date,
        completedBy: 'm-sam',
        completedFor: 'm-kid',
      );
      final shape = shapeOf(completion.toJson());
      expect(shape.keys, {
        'taskId',
        'occurrenceDate',
        'completedBy',
        'completedFor',
        'completedAt',
      });
      expect(shape.serverAssigned, {'completedAt'});
      // The rule checks the id against these two fields, so completing the same
      // occurrence twice is the same write (`BE-06`).
      expect(completion.id, 't_2026-09-18');
    });
  });

  group('events/{eventId}', () {
    test('writes the household"s wall clock, not an instant', () {
      final json = HouseholdEvent(
        id: 'e',
        title: 'School run',
        date: date,
        startMinute: 450,
        endMinute: 510,
        createdBy: 'm-sam',
      ).toJson();
      final shape = shapeOf(json);
      expect(shape.keys, {
        'title',
        'note',
        'date',
        'startMinute',
        'endMinute',
        'recurrence',
        'memberIds',
        'createdBy',
        'createdAt',
      });
      expect(shape.serverAssigned, {'createdAt'});
      expect(json['startMinute'], 450);
      expect(json['date'], '2026-09-18');
    });

    test('writes an all-day event with no times at all', () {
      final json = HouseholdEvent(
        id: 'e',
        title: 'Birthday',
        date: date,
        createdBy: 'm-sam',
      ).toJson();
      expect(json['startMinute'], isNull);
      expect(json['endMinute'], isNull);
    });
  });

  group('eventExceptions/{eventId}_{date}', () {
    test('writes the keys the rule names, and an id derived from them', () {
      final exception = EventException(
        id: EventException.idFor('e', date),
        eventId: 'e',
        occurrenceDate: date,
        skippedBy: 'm-sam',
      );
      final shape = shapeOf(exception.toJson());
      expect(shape.keys, {
        'eventId',
        'occurrenceDate',
        'skippedBy',
        'skippedAt',
      });
      expect(shape.serverAssigned, {'skippedAt'});
      expect(exception.id, 'e_2026-09-18');
    });
  });

  group('memberLocations/{memberId}', () {
    test('writes the four keys the rule names, and the server times it', () {
      final json = MemberLocation(
        id: 'm-sam',
        point: const Coordinates(latitude: -26.2041, longitude: 28.0473),
        accuracyMetres: 12,
        sharingUntil: DateTime.utc(2026, 9, 18, 15),
      ).toJson();
      final shape = shapeOf(json);

      expect(shape.keys, {
        'point',
        'accuracyMetres',
        'reportedAt',
        'sharingUntil',
      });
      // `reportedAt` is the server's, so how old a position is cannot be
      // something a device flatters itself about; `sharingUntil` is the
      // member's own and the rules bound it instead (live-location ADR-0001).
      expect(shape.serverAssigned, {'reportedAt'});
      expect(json['point'], isA<GeoPoint>());
      expect(json['sharingUntil'], isA<Timestamp>());
      expect(
        json.containsKey('memberId'),
        isFalse,
        reason:
            'the member id is the document id, which is what makes the rule '
            '`isOwnMember` on the path — a field here would be a second copy '
            'of it, and the wrong one to trust',
      );
    });
  });

  group('meals/{mealId}', () {
    test('writes a normalised key beside the name the person typed', () {
      final json = Meal.named(
        id: 'm',
        name: '  Spaghetti Bolognese ',
        addedBy: 'm-sam',
      ).toJson();
      final shape = shapeOf(json);
      expect(shape.keys, {'name', 'nameKey', 'addedBy', 'createdAt'});
      expect(shape.serverAssigned, {'createdAt'});
      expect(json['name'], 'Spaghetti Bolognese');
      // The rule insists the key is lower-cased.
      expect(json['nameKey'], 'spaghetti bolognese');
    });
  });

  group('mealPlans/{monday}', () {
    test('writes only its slots — the rule allows no other field', () {
      final json = const WeekPlan(
        id: '2026-09-14',
        slots: {'2_dinner': 'meal-1'},
      ).toJson();
      expect(json.keys.toSet(), {'slots'});
      expect(json['slots'], {'2_dinner': 'meal-1'});
    });

    test('never writes more slots than a week has', () {
      expect(WeekPlan.slotCount, 21);
    });
  });
}
