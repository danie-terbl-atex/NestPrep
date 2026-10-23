import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/meal_planning/model/meal.dart';
import 'package:nestprep/features/meal_planning/model/week_plan.dart';
import 'package:nestprep/features/recipes/state/recipe_catalogue_controller.dart';
import 'package:nestprep/features/recipes/state/recipe_page_controller.dart';
import 'package:nestprep/shared/async/async_state.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:nestprep/shared/time/calendar_date.dart';
import 'package:nestprep/shared/time/household_clock.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../../../support/fake_meal_repository.dart';
import '../../../support/fake_recipe_repository.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/recipe_fixtures.dart';

/// One recipe opened to cook or plan (recipes ADR-0003 §5, §6): who it is
/// cooked for, the ticks, and adding it to the week as a household meal.
void main() {
  setUpAll(tz_data.initializeTimeZones);

  late FakeRecipeRepository recipes;
  late FakeMealRepository meals;
  late RecipeCatalogueController catalogue;
  late RecipePageController page;

  RecipePageController pageFor(String recipeId, {int familySize = 4}) =>
      RecipePageController(
        mealRepository: meals,
        householdId: Fixtures.householdId,
        memberId: Fixtures.samMemberId,
        recipeId: recipeId,
        familySize: familySize,
      );

  setUp(() async {
    recipes = FakeRecipeRepository();
    meals = FakeMealRepository();
    catalogue = RecipeCatalogueController(
      recipeRepository: recipes,
      householdClock: HouseholdClock(
        'Africa/Johannesburg',
        now: () => DateTime.utc(2026, 10, 22, 9),
      ),
    );
    page = pageFor('bobotie');
    catalogue.addListener(() => page.followCatalogue(catalogue));
    recipes.emitCatalogue(RecipeFixtures.catalogue);
    await pumpEventQueue();
  });

  tearDown(() async {
    catalogue.dispose();
    page.dispose();
    await recipes.close();
    await meals.close();
  });

  test('a family meal starts at the family’s size, not the recipe’s', () {
    expect(page.scale?.people, 4);
    expect(page.scale?.servings, 6);
  });

  test('a lunch-box recipe starts at what it makes', () async {
    final wrap = pageFor('chicken-mayo-wrap')..followCatalogue(catalogue);
    addTearDown(wrap.dispose);
    expect(wrap.scale?.people, RecipeFixtures.wrap.servings);
  });

  test('adding and taking away people rescales every line', () {
    final mince = page.groups.first.lines.first;
    expect(mince.amount?.number, '665');
    page.addPerson();
    page.addPerson();
    expect(page.scale?.people, 6);
    expect(page.scale?.isAsWritten, isTrue);
    expect(page.groups.first.lines.first.amount?.number, '1');
    page.removePerson();
    expect(page.scale?.people, 5);
  });

  test('reset goes back to the recipe as written', () {
    page
      ..addPerson()
      ..addPerson()
      ..addPerson()
      ..resetToRecipe();
    expect(page.scale?.people, 6);
  });

  test('a line with no amount never scales', () {
    final salt = page.groups.first.lines.firstWhere(
      (line) => line.line.name == 'Salt',
    );
    expect(salt.amount, isNull);
  });

  test('the ingredients come in their parts, ticks kept by line', () {
    expect(page.groups.map((group) => group.title), [null, 'For the topping']);
    final eggs = page.groups.last.lines[1];
    page.toggleIngredient(eggs.index);
    expect(page.isTicked(eggs.index), isTrue);
    page.addPerson();
    expect(page.isTicked(eggs.index), isTrue, reason: 'scaling keeps ticks');
    page.toggleIngredient(eggs.index);
    expect(page.isTicked(eggs.index), isFalse);
  });

  test('a step is marked done and undone', () {
    page.toggleStep(2);
    expect(page.isDone(2), isTrue);
    expect(page.isDone(1), isFalse);
    page.toggleStep(2);
    expect(page.isDone(2), isFalse);
  });

  test('a recipe the catalogue does not hold is said to be missing', () {
    final gone = pageFor('retired')..followCatalogue(catalogue);
    addTearDown(gone.dispose);
    expect(gone.recipe, isA<AsyncData<Object?>>());
    expect((gone.recipe as AsyncData).value, isNull);
    expect(gone.scale, isNull);
  });

  group('adding it to the week', () {
    final thursday = CalendarDate(2026, 10, 22);

    test(
      'makes the household meal at the chosen scale, then fills the slot',
      () async {
        final isAdded = await page.addToWeek(
          day: thursday,
          slot: MealSlot.dinner,
        );
        expect(isAdded, isTrue);
        final meal = meals.recipeMeals.single;
        expect(meal.recipeId, 'bobotie');
        expect(meal.name, 'Bobotie');
        expect(meal.addedBy, Fixtures.samMemberId);
        expect(
          meal.ingredients
              .firstWhere((line) => line.name == 'Beef mince')
              .amount,
          665,
          reason: 'four people, not the six it is written for',
        );
        final slot = meals.writtenSlots.single;
        expect(slot.monday, '2026-10-19');
        expect(slot.slots, {'4_dinner': Meal.idForRecipe('bobotie')});
      },
    );

    test('cannot be pressed twice while the first is landing', () async {
      final hold = meals.holdRecipeMeal = Completer<void>();
      final first = page.addToWeek(day: thursday, slot: MealSlot.dinner);
      expect(page.isAdding, isTrue);
      expect(
        await page.addToWeek(day: thursday, slot: MealSlot.lunch),
        isFalse,
      );
      hold.complete();
      expect(await first, isTrue);
      expect(meals.recipeMeals, hasLength(1));
      expect(page.isAdding, isFalse);
    });

    test('a refusal is held as a failure for the page, never thrown', () async {
      meals.failWritesWith = const PermissionDeniedFailure();
      final isAdded = await page.addToWeek(
        day: thursday,
        slot: MealSlot.dinner,
      );
      expect(isAdded, isFalse);
      expect(page.actionFailure, const PermissionDeniedFailure());
      expect(meals.writtenSlots, isEmpty);
    });
  });

  group('shopping for it (recipes ADR-0005)', () {
    test('is planned once its meal is in the household library', () async {
      expect(page.isPlanned, isFalse);
      meals.emitMeals([
        Meal.named(
          id: Meal.idForRecipe('bobotie'),
          name: 'Bobotie',
          addedBy: Fixtures.samMemberId,
        ),
      ]);
      await pumpEventQueue();
      expect(page.isPlanned, isTrue);
    });

    test('another recipe’s meal does not count', () async {
      meals.emitMeals([
        Meal.named(
          id: Meal.idForRecipe('malva-pudding'),
          name: 'Malva pudding',
          addedBy: Fixtures.samMemberId,
        ),
      ]);
      await pumpEventQueue();
      expect(page.isPlanned, isFalse);
    });

    test('is planned the moment it is added to the week', () async {
      await page.addToWeek(
        day: CalendarDate(2026, 10, 22),
        slot: MealSlot.dinner,
      );
      expect(page.isPlanned, isTrue);
    });

    test('a meals read that fails is said, and the recipe stays', () async {
      meals.failMealsWith(const UnavailableFailure());
      await pumpEventQueue();
      expect(page.isPlanned, isFalse);
      expect(page.actionFailure, const UnavailableFailure());
      expect(page.recipe, isA<AsyncData<Object?>>());
    });

    test('what it still needs is every line not ticked off', () {
      page
        ..toggleIngredient(1)
        ..toggleIngredient(5);
      expect([
        for (final line in page.unticked) line.index,
      ], isNot(containsAll([1, 5])));
      expect(page.unticked.first.line.name, 'Beef mince');
      expect(
        page.unticked.length,
        RecipeFixtures.bobotie.ingredients.length - 2,
      );
    });
  });
}
