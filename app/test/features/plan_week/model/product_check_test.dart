import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/add_to_checkers/data/checkers_catalogue_parser.dart';
import 'package:nestprep/features/family_profiles/model/allergen.dart';
import 'package:nestprep/features/family_profiles/model/allergy_severity.dart';
import 'package:nestprep/features/family_profiles/model/dietary_flag.dart';
import 'package:nestprep/features/family_profiles/model/family_entry.dart';
import 'package:nestprep/features/family_profiles/model/family_profile.dart';
import 'package:nestprep/features/family_profiles/model/food_rules.dart';
import 'package:nestprep/features/family_profiles/model/other_allergy.dart';
import 'package:nestprep/features/lunch_box/model/lunch_slot.dart';
import 'package:nestprep/features/plan_week/model/allergen_words.dart';
import 'package:nestprep/features/plan_week/model/checked_product.dart';
import 'package:nestprep/features/plan_week/model/left_out_reason.dart';
import 'package:nestprep/features/plan_week/model/lunch_idea.dart';

import '../../../support/checkers_fakes_for_plan_week.dart';
import '../../../support/lunch_fixtures.dart';

/// NestPrep's own check of a shop's product and a lunch idea, child by child
/// (lunch-box ADR-0012 §2): the shop's words read for allergens, unknown
/// contents never offered to a child with allergies, and every leaving-out
/// said with its reason.
void main() {
  const lwazi = LunchFixtures.lwaziId;
  const ayanda = LunchFixtures.ayandaId;
  final rules = <String, FoodRules>{
    lwazi: LunchFixtures.lwaziEntry.foodRules,
    ayanda: LunchFixtures.ayandaEntry.foodRules,
  };

  group('the allergen words', () {
    test('read a shop line, "may contain" counting as contains', () {
      expect(
        AllergenWords.mentionedIn('Contains: Milk. May contain traces of soya'),
        {Allergen.milk, Allergen.soy},
      );
      expect(AllergenWords.mentionedIn('Apple slices'), isEmpty);
    });

    test('over-match on purpose: peanut butter is peanut and milk', () {
      expect(AllergenWords.mentionedIn('Peanut butter on bread'), {
        Allergen.peanut,
        Allergen.milk,
        Allergen.wheat,
      });
    });

    test('are the same lists the server holds', () {
      final server = File('../functions/src/plan_week/allergen_words.ts')
          .readAsStringSync();
      final entries = RegExp(r'(\w+): \[([^\]]*)\]').allMatches(server);
      final serverWords = {
        for (final entry in entries)
          entry.group(1)!: RegExp("'([^']*)'")
              .allMatches(entry.group(2)!)
              .map((word) => word.group(1))
              .toList(),
      };
      expect(serverWords, {
        for (final MapEntry(:key, :value) in AllergenWords.byAllergen.entries)
          key.name: value,
      });
    });
  });

  group('a shop product', () {
    final products = CheckersCatalogueParser.products(
      jsonDecode(
        File(
          'test/features/add_to_checkers/fixtures/'
          'products_filter_peanut_butter.json',
        ).readAsStringSync(),
      ),
    );

    test('naming peanuts is kept from the allergic child, for Ayanda', () {
      final smooth = CheckedProduct.of(products.first, rules);
      expect(smooth.allergens, containsAll([Allergen.peanut, Allergen.soy]));
      expect(smooth.childIds, {ayanda});
      expect(
        smooth.reasons.single,
        const LeftOutReason(
          LeftOutKind.allergy,
          childId: lwazi,
          allergen: Allergen.peanut,
        ),
      );
    });

    test('with no allergen information is never offered to a child with '
        'allergies', () {
      final riceCakes = CheckedProduct.of(
        planWeekProduct('Rice cakes 100g'),
        rules,
      );
      expect(riceCakes.isKnown, isFalse);
      expect(riceCakes.childIds, {ayanda});
      expect(riceCakes.reasons.single.kind, LeftOutKind.unknownContents);
    });

    test('out of stock, or sold by the kilogram, goes to nobody', () {
      final gone = CheckedProduct.of(
        planWeekProduct('Apples', isInStock: false, ingredients: 'Apples'),
        rules,
      );
      final weighed = CheckedProduct.of(
        planWeekProduct('Loose apples', unit: 'KG', ingredients: 'Apples'),
        rules,
      );
      expect(gone.isKept, isFalse);
      expect(gone.reasons.single.kind, LeftOutKind.outOfStock);
      expect(weighed.reasons.single.kind, LeftOutKind.soldByWeight);
    });

    test('a dislike is named, an allergy outranks it', () {
      final sauce = CheckedProduct.of(
        planWeekProduct('Tomato pasta', ingredients: 'Tomatoes, wheat'),
        {ayanda: rules[ayanda]!},
      );
      expect(sauce.reasons.single.kind, LeftOutKind.dislike);
      expect(sauce.reasons.single.word, 'Tomatoes');
    });

    test('nuts at a nut-free table are the nut rule, not an allergy', () {
      final nutFree = LunchFixtures.childOnDiet({DietaryFlag.nutFree});
      final almonds = CheckedProduct.of(
        planWeekProduct('Almond snack', ingredients: 'Almonds'),
        {ayanda: nutFree.foodRules},
      );
      expect(almonds.reasons.single.kind, LeftOutKind.nutRule);
    });

    test('a written allergy is matched in the ingredients', () {
      final kiwiChild = FamilyEntry(
        member: LunchFixtures.ayanda,
        profile: const FamilyProfile(
          id: ayanda,
          isChild: true,
          otherAllergies: {
            'k': OtherAllergy(name: 'Kiwi', severity: AllergySeverity.mild),
          },
        ),
      );
      final salad = CheckedProduct.of(
        planWeekProduct('Fruit salad', ingredients: 'Apple, kiwi, grape'),
        {ayanda: kiwiChild.foodRules},
      );
      expect(salad.reasons.single.kind, LeftOutKind.otherAllergy);
      expect(salad.reasons.single.word, 'Kiwi');
    });
  });

  group('an idea typed on the phone', () {
    test('is struck out per child, with the reason', () {
      final idea = LunchIdea.checked(
        id: 'own-1',
        slot: LunchSlot.snack,
        idea: 'Peanut butter crackers',
        rulesByChild: rules,
        origin: IdeaOrigin.own,
      );
      expect(idea.childIds, [ayanda]);
      expect(idea.excluded.single.childId, lwazi);
      expect(idea.isStruckOut, isFalse);
      expect(idea.searchTerm, 'Peanut butter crackers');
    });
  });
}
