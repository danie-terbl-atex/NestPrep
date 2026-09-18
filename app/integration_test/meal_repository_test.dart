import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nestprep/features/meal_planning/data/firestore_meal_repository.dart';
import 'package:nestprep/shared/time/calendar_date.dart';

import 'household_fixture.dart';

/// The repository layer, against the real Firestore in the emulator suite.
///
/// This is the layer `flutter test` cannot reach: `Firebase.initializeApp` needs
/// platform channels, so a unit test has no Firestore to talk to, and the six
/// repositories were absent from the coverage report rather than at 0%
/// (foundation ADR-0009).
///
/// A fake was measured instead of assumed and got `SetOptions(mergeFields:)`
/// wrong — it wiped a sibling key where Firestore preserves it. So the three
/// operations worth testing are tested here, on the real thing:
///
/// 1. `setSlots` merges only the named slots, which is the promise that two
///    people filling different days at the same time do not overwrite each
///    other.
/// 2. `deleteMeal` clears the meal out of every week that used it and deletes it
///    in one batch, so a plan never points at a meal that is gone.
/// 3. `addMeal` returns the existing meal rather than a duplicate when the same
///    name is typed again, deduplicated on the normalised name.
///
/// Run it with the suite up:
///
///     firebase emulators:start --project nestprep-643b7
///     flutter test integration_test/meal_repository_test.dart -d <device>
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late TestHousehold home;
  late FirestoreMealRepository meals;

  setUpAll(() async {
    home = await signInAndCreateAHousehold();
    meals = FirestoreMealRepository(home.firestore);
  });

  setUp(() async => home = await home.freshHousehold());

  tearDownAll(() async => home.signOut());

  group('setSlots merges only the slots it names', () {
    test('filling Wednesday leaves Tuesday alone', () async {
      // The one the fake got wrong, and the reason ADR-0009 exists. If this
      // fails, two members planning different days overwrite each other.
      final monday = CalendarDate(2026, 9, 21);

      await meals.setSlot(
        householdId: home.id,
        monday: monday,
        slotKey: '2026-09-22-dinner',
        mealId: 'tuesday-meal',
      );
      await meals.setSlot(
        householdId: home.id,
        monday: monday,
        slotKey: '2026-09-23-dinner',
        mealId: 'wednesday-meal',
      );

      final plan = await meals.readWeek(home.id, monday);
      expect(plan.slots['2026-09-22-dinner'], 'tuesday-meal');
      expect(plan.slots['2026-09-23-dinner'], 'wednesday-meal');
    });

    test('several slots at once, then one more, keeps all of them', () async {
      final monday = CalendarDate(2026, 9, 21);

      await meals.setSlots(
        householdId: home.id,
        monday: monday,
        slots: const {
          '2026-09-21-breakfast': 'oats',
          '2026-09-21-dinner': 'stew',
        },
      );
      await meals.setSlot(
        householdId: home.id,
        monday: monday,
        slotKey: '2026-09-21-lunch',
        mealId: 'sandwiches',
      );

      final plan = await meals.readWeek(home.id, monday);
      expect(plan.slots, hasLength(3));
      expect(plan.slots['2026-09-21-breakfast'], 'oats');
      expect(plan.slots['2026-09-21-dinner'], 'stew');
      expect(plan.slots['2026-09-21-lunch'], 'sandwiches');
    });

    test('setting the same slot again replaces just that one', () async {
      final monday = CalendarDate(2026, 9, 21);

      await meals.setSlots(
        householdId: home.id,
        monday: monday,
        slots: const {
          '2026-09-21-dinner': 'stew',
          '2026-09-22-dinner': 'pasta',
        },
      );
      await meals.setSlot(
        householdId: home.id,
        monday: monday,
        slotKey: '2026-09-21-dinner',
        mealId: 'curry',
      );

      final plan = await meals.readWeek(home.id, monday);
      expect(plan.slots['2026-09-21-dinner'], 'curry');
      expect(plan.slots['2026-09-22-dinner'], 'pasta');
    });
  });

  group('addMeal deduplicates on the normalised name', () {
    test(
      'typing a name the household already has returns the same id',
      () async {
        final first = await meals.addMeal(
          householdId: home.id,
          name: 'Spaghetti',
          addedBy: home.memberId,
        );
        final again = await meals.addMeal(
          householdId: home.id,
          name: 'spaghetti  ',
          addedBy: home.memberId,
        );

        expect(again, first, reason: 'a second Spaghetti is the first one');
      },
    );

    test('a different name is a different meal', () async {
      final one = await meals.addMeal(
        householdId: home.id,
        name: 'Spaghetti',
        addedBy: home.memberId,
      );
      final two = await meals.addMeal(
        householdId: home.id,
        name: 'Lasagne',
        addedBy: home.memberId,
      );

      expect(two, isNot(one));
    });
  });

  group('deleteMeal takes the meal out of the weeks that used it', () {
    test('both weeks clear, in one batch, and the meal is gone', () async {
      // Driven by hand on a device once and by nothing since — the hand-run
      // note calls it "deleting a meal and watching both weeks clear".
      final first = CalendarDate(2026, 9, 21);
      final second = CalendarDate(2026, 9, 28);

      final mealId = await meals.addMeal(
        householdId: home.id,
        name: 'Stew',
        addedBy: home.memberId,
      );
      final keeper = await meals.addMeal(
        householdId: home.id,
        name: 'Salad',
        addedBy: home.memberId,
      );

      await meals.setSlots(
        householdId: home.id,
        monday: first,
        slots: {'2026-09-21-dinner': mealId, '2026-09-22-dinner': keeper},
      );
      await meals.setSlot(
        householdId: home.id,
        monday: second,
        slotKey: '2026-09-28-dinner',
        mealId: mealId,
      );

      await meals.deleteMeal(
        householdId: home.id,
        mealId: mealId,
        weeksToClear: [first, second],
      );

      final weekOne = await meals.readWeek(home.id, first);
      final weekTwo = await meals.readWeek(home.id, second);

      expect(weekOne.slots.containsKey('2026-09-21-dinner'), isFalse);
      expect(
        weekOne.slots['2026-09-22-dinner'],
        keeper,
        reason: 'the other meal in the same week must survive',
      );
      expect(weekTwo.slots, isEmpty);

      final library = await meals.watchMeals(home.id).first;
      expect(library.map((meal) => meal.id), isNot(contains(mealId)));
      expect(library.map((meal) => meal.id), contains(keeper));
    });

    test('a week that never used it is left untouched', () async {
      final used = CalendarDate(2026, 9, 21);
      final other = CalendarDate(2026, 9, 28);

      final mealId = await meals.addMeal(
        householdId: home.id,
        name: 'Stew',
        addedBy: home.memberId,
      );
      await meals.setSlot(
        householdId: home.id,
        monday: used,
        slotKey: '2026-09-21-dinner',
        mealId: mealId,
      );
      await meals.setSlot(
        householdId: home.id,
        monday: other,
        slotKey: '2026-09-28-dinner',
        mealId: 'something-else',
      );

      await meals.deleteMeal(
        householdId: home.id,
        mealId: mealId,
        weeksToClear: [used, other],
      );

      final untouched = await meals.readWeek(home.id, other);
      expect(untouched.slots['2026-09-28-dinner'], 'something-else');
    });
  });
}
