import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/family_profiles/model/allergen.dart';
import 'package:nestprep/features/family_profiles/model/dietary_flag.dart';
import 'package:nestprep/features/family_profiles/model/food_rules.dart';
import 'package:nestprep/features/lunch_box/model/lunch_concern.dart';
import 'package:nestprep/features/lunch_box/model/lunch_safety.dart';

import '../../../support/lunch_fixtures.dart';

/// The app's half of the allergy rule (lunch-box ADR-0001): what it flags and
/// leaves out of suggestions. The rules suite proves the server refuses the
/// same boxes.
void main() {
  final lwazi = LunchFixtures.lwaziEntry.foodRules;
  final ayanda = LunchFixtures.ayandaEntry.foodRules;

  List<LunchConcern> concerns(
    String name,
    Set<Allergen> allergens,
    FoodRules rules,
  ) => LunchSafety.concernsFor(name: name, allergens: allergens, rules: rules);

  test('an allergen the child reacts to is unsafe, and named', () {
    final found = concerns('Peanut butter sandwich', {
      Allergen.peanut,
      Allergen.wheat,
    }, lwazi);
    expect(found, [const AllergenConcern(Allergen.peanut)]);
    expect(found.single.isUnsafe, isTrue);
  });

  test('a nut allergy is said once, not again as the nut rule', () {
    final found = concerns('Nut bar', {
      Allergen.peanut,
      Allergen.treeNut,
    }, lwazi);
    expect(found, contains(const AllergenConcern(Allergen.peanut)));
    // Tree nuts are ruled out too, but the allergy already says the box is
    // unsafe and why; a second nut tag would be noise beside it.
    expect(found.whereType<NutRuleConcern>(), isEmpty);
  });

  test('a nut-free school keeps tree nuts out of a peanut-allergic box', () {
    final found = concerns('Trail mix', {Allergen.treeNut}, lwazi);
    expect(found, hasLength(1));
    final rule = found.single as NutRuleConcern;
    expect(rule.reasons, containsAll([NutFreeReason.school]));
    expect(rule.isUnsafe, isTrue);
  });

  test('a family nut-free diet rules nuts out with no allergy at all', () {
    final rules = LunchFixtures.childOnDiet({DietaryFlag.nutFree}).foodRules;
    expect(
      LunchSafety.isSafe(allergens: {Allergen.peanut}, rules: rules),
      isFalse,
    );
    expect(
      LunchSafety.isSafe(allergens: {Allergen.milk}, rules: rules),
      isTrue,
    );
  });

  test('nothing is said about a child with no rules and no dislikes', () {
    final rules = LunchFixtures.childOnDiet(const {}).foodRules;
    expect(concerns('Trail mix', {Allergen.treeNut}, rules), isEmpty);
    expect(
      LunchSafety.isSafe(allergens: {Allergen.peanut}, rules: rules),
      isTrue,
    );
  });

  test('a dislike is a concern, but never a safety one', () {
    final found = concerns('Cheese and tomato sandwich', {
      Allergen.milk,
    }, ayanda);
    expect(found, [const DislikeConcern('Tomatoes')]);
    expect(found.single.isUnsafe, isFalse);
  });

  group('whether a name mentions a dislike', () {
    test('matches singular and plural, any case', () {
      expect(LunchSafety.mentions('Cherry tomatoes', 'tomato'), isTrue);
      expect(LunchSafety.mentions('Cheese & tomato roll', 'Tomatoes'), isTrue);
      expect(LunchSafety.mentions('Strawberries', 'strawberry'), isTrue);
      expect(LunchSafety.mentions('Mushroom pie', 'MUSHROOMS'), isTrue);
    });

    test('only at the start of a word', () {
      expect(LunchSafety.mentions('Veggie wrap', 'egg'), isFalse);
      expect(LunchSafety.mentions('Doughnut', 'nuts'), isFalse);
      expect(LunchSafety.mentions('Egg mayo', 'egg'), isTrue);
    });

    test('never from a word too short to mean anything', () {
      expect(LunchSafety.mentions('Apple', 'a'), isFalse);
    });
  });
}
