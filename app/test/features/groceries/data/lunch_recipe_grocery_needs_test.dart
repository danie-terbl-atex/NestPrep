import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/family_profiles/model/allergen.dart';
import 'package:nestprep/features/groceries/data/lunch_plan_grocery_source.dart';
import 'package:nestprep/features/groceries/model/grocery_amount.dart';
import 'package:nestprep/features/groceries/model/grocery_need.dart';
import 'package:nestprep/features/groceries/model/grocery_need_reason.dart';
import 'package:nestprep/features/lunch_box/data/lunch_week_reader.dart';
import 'package:nestprep/features/lunch_box/model/lunch_item.dart';
import 'package:nestprep/features/lunch_box/model/lunch_pick.dart';
import 'package:nestprep/features/lunch_box/model/lunch_slot.dart';
import 'package:nestprep/features/lunch_box/model/lunch_week_items.dart';
import 'package:nestprep/features/meal_planning/model/ingredient_unit.dart';
import 'package:nestprep/features/recipes/model/recipe.dart';
import 'package:nestprep/features/recipes/model/recipe_context.dart';
import 'package:nestprep/features/recipes/model/recipe_ingredient.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/fake_lunch_repository.dart';
import '../../../support/fake_recipe_repository.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/lunch_fixtures.dart';

/// A lunch item made from a recipe reaches the list as the recipe's
/// ingredients, scaled by the boxes it fills; everything else in a box is
/// still counted, never converted (groceries ADR-0006).
void main() {
  const wrapRecipe = Recipe(
    id: 'ai-wrap',
    name: 'Mexican wholewheat wrap',
    summary: '',
    contexts: {RecipeContext.lunchBox},
    placement: {RecipeContext.lunchBox: 'main'},
    allergens: {Allergen.wheat},
    dietTags: [],
    ingredients: [
      RecipeIngredient(name: 'Wholewheat tortillas', quantity: 1),
      RecipeIngredient(name: 'Chicken strips', quantity: 50, unit: 'g'),
      RecipeIngredient(name: 'Salsa', quantity: 2, unit: 'tbsp'),
      RecipeIngredient(name: 'Lettuce', quantity: 2, unit: 'leaves'),
      RecipeIngredient(name: 'Salt'),
    ],
    steps: ['Fill and roll.'],
    servings: 1,
    prepMinutes: 10,
    prepAhead: false,
    isAiDrafted: true,
  );

  final wrapItem = LunchItem.named(
    id: 'wrap-dish',
    name: 'Mexican wholewheat wrap',
    slot: LunchSlot.main,
    allergens: const {Allergen.wheat},
    addedBy: Fixtures.samMemberId,
    householdRecipeId: 'ai-wrap',
  );

  Future<List<GroceryNeed>> needsFor(FakeRecipeRepository recipes) async {
    final lunches = FakeLunchRepository();
    addTearDown(lunches.close);
    final emitted = <List<GroceryNeed>>[];
    final subscription = LunchPlanGrocerySource(
      LunchWeekReader(lunches),
      recipes,
    ).watchNeeds(Fixtures.householdId, LunchFixtures.week).listen(emitted.add);
    addTearDown(subscription.cancel);
    final wrap = LunchPick.of(wrapItem);
    final apple = LunchPick.of(LunchFixtures.apple);
    lunches
      ..emitItems([wrapItem, LunchFixtures.apple])
      ..emitPlans([
        LunchFixtures.plan(
          LunchFixtures.lwaziId,
          slots: {
            for (var day = 1; day <= 5; day++)
              LunchFixtures.key(day, LunchSlot.main): wrap,
            LunchFixtures.key(1, LunchSlot.fruit): apple,
          },
        ),
      ]);
    await pumpEventQueue();
    return emitted.last;
  }

  GroceryNeed named(List<GroceryNeed> needs, String name) =>
      needs.singleWhere((need) => need.name == name);

  test(
    'five wraps need five tortillas and 250 g of chicken, never "a wrap"',
    () async {
      final needs = await needsFor(FakeRecipeRepository([wrapRecipe]));
      expect(needs.map((need) => need.name), isNot(contains(wrapItem.name)));
      expect(
        named(needs, 'Wholewheat tortillas').amount,
        const GroceryAmount(5),
      );
      expect(
        named(needs, 'Chicken strips').amount,
        const GroceryAmount(250, IngredientUnit.gram),
      );
      expect(
        named(needs, 'Chicken strips').reason,
        const LunchPlanReason(boxes: 5, childIds: [LunchFixtures.lwaziId]),
      );
    },
  );

  test('a kitchen measure stays a measure; a unit this build does not know is no amount', () async {
    final needs = await needsFor(FakeRecipeRepository([wrapRecipe]));
    expect(
      named(needs, 'Salsa').amount,
      const GroceryAmount(10, IngredientUnit.tablespoon),
    );
    expect(named(needs, 'Lettuce').amount, isNull);
    expect(named(needs, 'Salt').amount, isNull);
  });

  test('a catalogue recipe serving four is scaled by its servings', () {
    final needs = LunchPlanGrocerySource.needsOf(
      [
        LunchWeekItem(
          itemId: wrapItem.id,
          name: wrapItem.name,
          slot: LunchSlot.main,
          portions: 2,
          childIds: const [LunchFixtures.lwaziId],
          allergens: wrapItem.allergens,
          recipeLink: wrapItem.recipeLink,
        ),
      ],
      recipes: {
        wrapItem.recipeLink!: wrapRecipe.copyWith(
          servings: 4,
          ingredients: const [
            RecipeIngredient(name: 'Pasta', quantity: 400, unit: 'g'),
          ],
        ),
      },
    );
    expect(needs.single.amount, const GroceryAmount(200, IngredientUnit.gram));
  });

  test(
    'a recipe that cannot be read is counted like any item — never lost',
    () async {
      final needs = await needsFor(FakeRecipeRepository());
      expect(named(needs, wrapItem.name).amount, isNull);
      expect(named(needs, 'Apple slices').amount, isNull);
    },
  );

  test(
    'a failed recipe read counts that item and keeps every other need',
    () async {
      final recipes = FakeRecipeRepository([wrapRecipe])
        ..failWith = const UnavailableFailure();
      final errors = <Object>[];
      final lunches = FakeLunchRepository();
      addTearDown(lunches.close);
      final emitted = <List<GroceryNeed>>[];
      final subscription =
          LunchPlanGrocerySource(LunchWeekReader(lunches), recipes)
              .watchNeeds(Fixtures.householdId, LunchFixtures.week)
              .listen(emitted.add, onError: errors.add);
      addTearDown(subscription.cancel);
      lunches
        ..emitItems([wrapItem, LunchFixtures.apple])
        ..emitPlans([
          LunchFixtures.plan(
            LunchFixtures.lwaziId,
            slots: {
              LunchFixtures.key(1, LunchSlot.main): LunchPick.of(wrapItem),
              LunchFixtures.key(1, LunchSlot.fruit): LunchPick.of(
                LunchFixtures.apple,
              ),
            },
          ),
        ]);
      await pumpEventQueue();
      expect(errors, isEmpty);
      expect(
        emitted.last.map((need) => need.name),
        containsAll([wrapItem.name, 'Apple slices']),
      );
    },
  );

  test(
    'reads each recipe once — they never change — not on every emission',
    () async {
      final recipes = FakeRecipeRepository([wrapRecipe]);
      final lunches = FakeLunchRepository();
      addTearDown(lunches.close);
      final subscription = LunchPlanGrocerySource(
        LunchWeekReader(lunches),
        recipes,
      ).watchNeeds(Fixtures.householdId, LunchFixtures.week).listen((_) {});
      addTearDown(subscription.cancel);
      for (var day = 1; day <= 3; day++) {
        lunches
          ..emitItems([wrapItem])
          ..emitPlans([
            LunchFixtures.plan(
              LunchFixtures.lwaziId,
              slots: {
                for (var d = 1; d <= day; d++)
                  LunchFixtures.key(d, LunchSlot.main): LunchPick.of(wrapItem),
              },
            ),
          ]);
        await pumpEventQueue();
      }
      expect(recipes.linked, hasLength(1));
    },
  );
}
