import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/family_profiles/model/allergen.dart';
import 'package:nestprep/features/family_profiles/model/allergy_detail.dart';
import 'package:nestprep/features/family_profiles/model/allergy_severity.dart';
import 'package:nestprep/features/family_profiles/model/family_profile.dart';
import 'package:nestprep/features/family_profiles/model/food_rules.dart';
import 'package:nestprep/features/lunch_box/model/fill_week_box.dart';
import 'package:nestprep/features/lunch_box/model/lunch_box.dart';
import 'package:nestprep/features/lunch_box/model/lunch_concern.dart';
import 'package:nestprep/features/lunch_box/model/lunch_favourite.dart';
import 'package:nestprep/features/lunch_box/model/lunch_pick.dart';
import 'package:nestprep/features/lunch_box/model/lunch_slot.dart';
import 'package:nestprep/features/lunch_box/model/lunch_starter_box.dart';

import '../../../support/fake_starter_boxes.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/lunch_fixtures.dart';

/// A box on offer in *Fill the week* (lunch-box ADR-0020), as one child
/// would have it: every compartment checked with the board's own food-rule
/// check; a ready-made box chosen with its unsafe compartments left for
/// NestPrep and its treat on Fridays only; a go-to box with anything unsafe
/// never chosen at all.
void main() {
  final lwazi = LunchFixtures.lwaziEntry.foodRules;
  final ayanda = LunchFixtures.ayandaEntry.foodRules;
  final library = {for (final item in LunchFixtures.library) item.id: item};

  FillWeekBox readyMade(LunchStarterBox box, FoodRules rules) =>
      FillWeekBox.readyMade(
        box,
        recipes: {
          for (final recipe in StarterBoxFixtures.recipes) recipe.id: recipe,
        },
        rules: rules,
        library: library,
        addedBy: Fixtures.samMemberId,
      );

  FillWeekBox goTo(Map<LunchSlot, LunchPick> picks, FoodRules rules) =>
      FillWeekBox.goTo(
        LunchFavourite.of(
          id: 'fav',
          childId: LunchFixtures.lwaziId,
          name: 'Our Monday',
          box: LunchBox(picks),
          createdBy: Fixtures.samMemberId,
        ),
        rules: rules,
        library: library,
      );

  test('trail mix is not right for Lwazi: the ready-made box can still be '
      'chosen, and its snack is left for NestPrep to fill, saying why', () {
    final trail = readyMade(StarterBoxFixtures.trail, lwazi);
    expect(trail.canBeChosen, isTrue);
    final snack = trail.compartments.single;
    expect(snack.isSafe, isFalse);
    expect(snack.unsafe.first, isA<AllergenConcern>());
    expect(trail.packsOn(1), isEmpty);
  });

  test('the same box is whole for Ayanda', () {
    final trail = readyMade(StarterBoxFixtures.trail, ayanda);
    expect(trail.hasUnsafe, isFalse);
    expect(trail.packsOn(1).keys, [LunchSlot.snack]);
  });

  test('a ready-made treat goes in on Friday only', () {
    final classic = readyMade(StarterBoxFixtures.classic, ayanda);
    expect(classic.packsOn(1).keys, isNot(contains(LunchSlot.treat)));
    expect(classic.packsOn(DateTime.friday).keys, contains(LunchSlot.treat));
  });

  test('a recipe\'s own allergens count, not only the box\'s', () {
    // The box lists the muffin as wheat and egg; the recipe adds milk.
    final milk = FoodRules(
      profile: const FamilyProfile(
        id: LunchFixtures.ayandaId,
        isChild: true,
        allergies: {
          Allergen.milk: AllergyDetail(severity: AllergySeverity.mild),
        },
      ),
    );
    final classic = readyMade(StarterBoxFixtures.classic, milk);
    final treat = classic.compartments.firstWhere(
      (each) => each.slot == LunchSlot.treat,
    );
    expect(treat.isSafe, isFalse);
    expect(treat.isRecipe, isTrue);
    expect(classic.packsOn(DateTime.friday), isNot(contains(LunchSlot.treat)));
  });

  test('a ready-made compartment is the library item it becomes — '
      'recipe-<id> or seed-<key> — written before it is packed', () {
    final classic = readyMade(StarterBoxFixtures.classic, ayanda);
    expect(
      classic.packsOn(1)[LunchSlot.main]!.itemId,
      'recipe-test-hummus-wrap',
    );
    expect(classic.packsOn(1)[LunchSlot.fruit]!.itemId, 'seed-apple');
    expect(classic.candidates.keys, {
      'recipe-test-hummus-wrap',
      'seed-apple',
      'recipe-test-oat-muffin',
    });
  });

  test('a go-to box with anything unsafe for the child cannot be chosen', () {
    final unsafe = goTo({
      LunchSlot.main: LunchPick.of(LunchFixtures.peanutButter),
      LunchSlot.fruit: LunchPick.of(LunchFixtures.apple),
    }, lwazi);
    expect(unsafe.canBeChosen, isFalse);
    final safe = goTo({
      LunchSlot.main: LunchPick.of(LunchFixtures.wrap),
    }, lwazi);
    expect(safe.canBeChosen, isTrue);
  });

  test('a go-to box packs its treat on any day, as it was saved', () {
    final withTreat = goTo({
      LunchSlot.main: LunchPick.of(LunchFixtures.wrap),
      LunchSlot.treat: LunchPick.of(LunchFixtures.muffin),
    }, ayanda);
    expect(withTreat.packsOn(1).keys, contains(LunchSlot.treat));
  });

  test('a go-to box\'s picks are the library\'s items as they are now', () {
    final stale = goTo({
      LunchSlot.main: const LunchPick(itemId: 'wrap', name: 'Old name'),
    }, ayanda);
    expect(stale.packsOn(1)[LunchSlot.main]!.name, 'Chicken wrap');
  });
}
