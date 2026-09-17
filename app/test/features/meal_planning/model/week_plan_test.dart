import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/meal_planning/model/meal.dart';
import 'package:nestprep/features/meal_planning/model/week_plan.dart';
import 'package:nestprep/shared/time/calendar_date.dart';

void main() {
  group('a meal', () {
    test('keeps the spelling typed and a normalised key beside it', () {
      final meal = Meal.named(
        id: 'm',
        name: '  Full  Cream Pasta ',
        addedBy: 'x',
      );
      expect(meal.name, 'Full  Cream Pasta');
      expect(meal.nameKey, 'full cream pasta');
    });

    test('two spellings of the same meal share a key', () {
      expect(
        Meal.named(id: 'a', name: 'Spaghetti', addedBy: 'x').nameKey,
        Meal.named(id: 'b', name: '  spaghetti ', addedBy: 'x').nameKey,
      );
    });
  });

  group('a week plan', () {
    final monday = CalendarDate.parse('2026-09-14');

    test('starts empty and knows it', () {
      expect(WeekPlan.empty(monday).isEmpty, isTrue);
      expect(WeekPlan.empty(monday).mealIdAt(2, MealSlot.dinner), isNull);
    });

    test(
      'keys a slot by weekday and meal, so copying a week is the same keys',
      () {
        expect(WeekPlan.slotKey(2, MealSlot.dinner), '2_dinner');
        const plan = WeekPlan(
          id: '2026-09-14',
          slots: {'2_dinner': 'spaghetti'},
        );
        expect(plan.mealIdAt(2, MealSlot.dinner), 'spaghetti');
        expect(plan.mealIdAt(2, MealSlot.lunch), isNull);
        expect(plan.isEmpty, isFalse);
      },
    );

    test('a cleared slot is empty, not planned', () {
      const plan = WeekPlan(id: '2026-09-14', slots: {'2_dinner': ''});
      expect(plan.isEmpty, isTrue);
      expect(plan.filledSlots, isEmpty);
    });
  });

  group('copying last week', () {
    final monday = CalendarDate.parse('2026-09-21');
    const previous = WeekPlan(
      id: '2026-09-14',
      slots: {'2_dinner': 'spaghetti', '4_dinner': 'curry', '1_lunch': ''},
    );

    test('fills only the empty slots', () {
      final thisWeek = WeekPlan(id: monday.iso, slots: {'2_dinner': 'pizza'});
      expect(thisWeek.slotsCopiedFrom(previous), {'4_dinner': 'curry'});
    });

    test('replaces everything when overwrite is asked for', () {
      final thisWeek = WeekPlan(id: monday.iso, slots: {'2_dinner': 'pizza'});
      expect(thisWeek.slotsCopiedFrom(previous, overwrite: true), {
        '2_dinner': 'spaghetti',
        '4_dinner': 'curry',
      });
    });

    test('never copies an empty slot forward', () {
      expect(
        WeekPlan.empty(monday).slotsCopiedFrom(previous).containsKey('1_lunch'),
        isFalse,
      );
    });

    test('has nothing to copy from a week nobody planned', () {
      expect(
        WeekPlan.empty(monday).slotsCopiedFrom(WeekPlan.empty(monday)),
        isEmpty,
      );
    });
  });

  group('deleting a meal', () {
    test('names every slot that used it, and no others', () {
      const plan = WeekPlan(
        id: '2026-09-14',
        slots: {
          '2_dinner': 'spaghetti',
          '4_dinner': 'spaghetti',
          '5_lunch': 'curry',
        },
      );
      expect(plan.slotsUsing('spaghetti'), ['2_dinner', '4_dinner']);
      expect(plan.slotsUsing('pizza'), isEmpty);
    });
  });

  group('the stored shape', () {
    test('does not write its own id, which is the week it is for', () {
      const plan = WeekPlan(id: '2026-09-14', slots: {'2_dinner': 'spaghetti'});
      final json = plan.toJson();
      expect(json.containsKey('id'), isFalse);
      expect(WeekPlan.fromJson({...json, 'id': '2026-09-14'}), plan);
    });

    test('reads a document written before it had any slots', () {
      expect(WeekPlan.fromJson({'id': '2026-09-14'}).slots, isEmpty);
    });
  });
}
