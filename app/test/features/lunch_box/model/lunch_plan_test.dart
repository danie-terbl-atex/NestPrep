import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/family_profiles/model/allergen.dart';
import 'package:nestprep/features/lunch_box/model/lunch_feedback.dart';
import 'package:nestprep/features/lunch_box/model/lunch_item.dart';
import 'package:nestprep/features/lunch_box/model/lunch_item_draft.dart';
import 'package:nestprep/features/lunch_box/model/lunch_pick.dart';
import 'package:nestprep/features/lunch_box/model/lunch_plan.dart';
import 'package:nestprep/features/lunch_box/model/lunch_seed_catalogue.dart';
import 'package:nestprep/features/lunch_box/model/lunch_slot.dart';

import '../../../support/household_fixtures.dart';
import '../../../support/lunch_fixtures.dart';

void main() {
  group('a plan', () {
    test('is filed under the child and the ISO week', () {
      final plan = LunchFixtures.plan(LunchFixtures.lwaziId);
      expect(plan.id, 'm-kid_2026-W40');
      expect(plan.week, '2026-W40');
      expect(plan.weekStart, '2026-09-28');
      expect(plan.lunchWeek, LunchFixtures.week);
    });

    test('has five slots on each of five days, and no more', () {
      expect(LunchPlan.allSlotKeys, hasLength(25));
      expect(LunchPlan.allSlotKeys.first, '1_main');
      expect(LunchPlan.allSlotKeys.last, '5_treat');
    });

    test('reads a day as a box, compartment by compartment', () {
      final plan = LunchFixtures.plan(
        LunchFixtures.lwaziId,
        slots: {'3_fruit': LunchPick.of(LunchFixtures.apple)},
      );
      final box = plan.boxOn(3);
      expect(box[LunchSlot.fruit]?.name, 'Apple slices');
      expect(box.filledCount, 1);
      expect(plan.boxOn(2).isEmpty, isTrue);
    });
  });

  group('a mark', () {
    test('judges an unmarked item with the box', () {
      final mark = LunchFixtures.feedback(
        LunchVerdict.ate,
        items: {LunchSlot.veg: LunchVerdict.left},
      );
      expect(mark.verdictFor(LunchSlot.main), LunchVerdict.ate);
      expect(mark.verdictFor(LunchSlot.veg), LunchVerdict.left);
      expect(mark.isMarkedOnItsOwn(LunchSlot.veg), isTrue);
      expect(mark.isMarkedOnItsOwn(LunchSlot.main), isFalse);
    });

    test('with a word this build does not know says nothing', () {
      const mark = LunchFeedback(verdict: 'maybe', by: Fixtures.samMemberId);
      expect(mark.boxVerdict, isNull);
      expect(mark.verdictFor(LunchSlot.main), isNull);
    });
  });

  group('an item', () {
    test(
      'keeps its allergens in the vocabulary’s order, and its key normalised',
      () {
        final item = LunchItem.named(
          id: 'x',
          name: '  Egg   Mayo ',
          slot: LunchSlot.main,
          allergens: {Allergen.wheat, Allergen.egg},
          addedBy: Fixtures.samMemberId,
        );
        expect(item.name, 'Egg   Mayo');
        expect(item.nameKey, 'egg mayo');
        expect(item.allergens, ['egg', 'wheat']);
        expect(item.knownAllergens, {Allergen.egg, Allergen.wheat});
      },
    );

    test('keeps a code a newer build added when it is edited here', () {
      final stored = LunchFixtures.cheese.copyWith(
        allergens: ['milk', 'lupin'],
      );
      final edited = const LunchItemDraft(
        name: 'Cheese roll',
        slot: LunchSlot.main,
        allergens: {Allergen.milk, Allergen.wheat},
      ).applyTo(stored);
      expect(edited.allergens, ['milk', 'wheat', 'lupin']);
      expect(edited.nameKey, 'cheese roll');
      expect(edited.slotName, 'main');
    });

    test('drops a prep note when it is no longer made ahead', () {
      final edited = const LunchItemDraft(
        name: 'Carrot sticks',
        slot: LunchSlot.veg,
        allergens: {},
        prepNote: 'Cut on Sunday',
      ).applyTo(LunchFixtures.carrots);
      expect(edited.prepAhead, isFalse);
      expect(edited.prepNote, isNull);
    });

    test('a draft with no name, or too long a one, is not an item', () {
      expect(
        const LunchItemDraft(
          name: '  ',
          slot: LunchSlot.fruit,
          allergens: {},
        ).isValid,
        isFalse,
      );
      expect(
        LunchItemDraft(
          name: 'x' * (LunchItem.nameLimit + 1),
          slot: LunchSlot.fruit,
          allergens: const {},
        ).isValid,
        isFalse,
      );
    });
  });

  group('the starter library', () {
    final items = LunchSeedCatalogue.itemsFor(Fixtures.samMemberId);

    test('has something for every slot', () {
      for (final slot in LunchSlot.values) {
        expect(items.where((item) => item.slot == slot), isNotEmpty);
      }
    });

    test(
      'has fixed, unique ids, so seeding twice writes the same documents',
      () {
        expect(items.map((item) => item.id).toSet(), hasLength(items.length));
        expect(
          LunchSeedCatalogue.itemsFor('someone-else').map((item) => item.id),
          items.map((item) => item.id),
        );
        expect(items.every((item) => item.id.startsWith('seed-')), isTrue);
      },
    );

    test('says what is in things, so the first box is already checked', () {
      final peanutButter = items.firstWhere(
        (item) => item.seedKey == 'peanut-butter',
      );
      expect(peanutButter.knownAllergens, contains(Allergen.peanut));
      final trail = items.firstWhere((item) => item.seedKey == 'trail-mix');
      expect(
        trail.knownAllergens,
        containsAll([Allergen.peanut, Allergen.treeNut]),
      );
    });

    test('marks what is worth making on Sunday, with how', () {
      final prepped = items.where((item) => item.prepAhead);
      expect(prepped, isNotEmpty);
      expect(prepped.every((item) => item.prepNote != null), isTrue);
    });

    test('fits the rules’ limits', () {
      for (final item in items) {
        expect(item.name.length, lessThanOrEqualTo(LunchItem.nameLimit));
        expect(
          item.prepNote?.length ?? 0,
          lessThanOrEqualTo(LunchItem.prepNoteLimit),
        );
      }
    });
  });
}
