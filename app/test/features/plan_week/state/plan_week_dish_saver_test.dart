import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/family_profiles/model/allergen.dart';
import 'package:nestprep/features/live_location/model/coordinates.dart';
import 'package:nestprep/features/lunch_box/model/lunch_slot.dart';
import 'package:nestprep/features/plan_week/data/shop_week_groceries.dart';
import 'package:nestprep/features/plan_week/state/shop_week_saver.dart';
import 'package:nestprep/features/plan_week/state/store_search_run.dart';
import 'package:nestprep/features/recipes/model/recipe_link.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/fake_plan_week.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/lunch_fixtures.dart';
import '../../../support/lunch_planning_harness.dart';
import '../../../support/plan_week_dish_fixture.dart';

/// Using a week with a dish (lunch-box ADR-0021 §5, recipes ADR-0002): its
/// ingredients searched one by one, then — in order — its household recipe,
/// its library item named after the dish and linked to that recipe, its
/// price for the boxes it fills, and the boxes. A recipe that cannot be
/// saved writes nothing. The basket reaches the list under ingredient names.
void main() {
  late LunchPlanningHarness harness;
  late FakeLunchRecipeSaver recipes;
  late ShopWeekSaver saver;

  setUp(() async {
    harness = LunchPlanningHarness();
    recipes = FakeLunchRecipeSaver();
    saver = ShopWeekSaver(
      lunchRepository: harness.lunch.repository,
      budgetRepository: harness.budgetRepository,
      recipeSaver: recipes,
      householdId: Fixtures.householdId,
      memberId: Fixtures.samMemberId,
    );
  });
  tearDown(() => harness.close());

  test(
    'searches a dish one ingredient at a time, each judged for its children',
    () async {
      final shop = FakeShopCatalogue()
        ..byQuery['wholewheat tortillas'] = [PlanWeekDishFixture.tortillas]
        ..failFor['chicken strips'] = const UnavailableFailure();
      final run = StoreSearchRun(onChange: () {});
      await run.start(
        catalogue: shop,
        ideas: [PlanWeekDishFixture.idea],
        near: const Coordinates(latitude: -33.92, longitude: 18.42),
        rulesByChild: PlanWeekDishFixture.rules,
      );
      final search = run.searches.single;
      expect(run.isSettled, isTrue);
      expect(search.isDish, isTrue);
      expect(search.ingredients.map((find) => find.found.length), [1, 0]);
      expect(search.ingredients.last.failure, isA<UnavailableFailure>());
      // Without chicken there is no dish to plan (lunch-box ADR-0023 §2).
      expect(search.dishChildIds, isEmpty);
      expect(run.hasKept, isFalse);
    },
  );

  test('saves the recipe, then the dish item linked to it, then its price and boxes', () async {
    final plan = PlanWeekDishFixture.plannedWeek();
    final saved = await saver.save(plan, board: PlanWeekDishFixture.board());

    final sent = recipes.saved.single.single;
    expect(sent.draft.name, 'Mexican wholewheat wrap');
    expect(
      sent.alsoContains,
      contains(Allergen.soy),
      reason: 'the label says soya',
    );

    final item = harness.lunch.repository.seeded.single.single;
    expect(item.id, 'dish-ai-1');
    expect(item.name, 'Mexican wholewheat wrap');
    expect(item.slot, LunchSlot.main);
    expect(item.recipeLink, const HouseholdRecipeLink('ai-1'));
    expect(item.knownAllergens, containsAll([Allergen.wheat, Allergen.soy]));
    expect(item.prepAhead, isTrue);

    final price = harness.budgetRepository.setPrices.single;
    expect(price.id, 'dish-ai-1');
    expect(price.cents, 3000 + 2 * 6000);
    expect(price.portions, 5);

    expect(saved.lunches, 5);
    final write = harness.lunch.repository.writtenPicks.single;
    expect(write.childId, PlanWeekDishFixture.ayanda);
    expect(write.picks, hasLength(5));
    expect(
      write.picks.values.every((pick) => pick?.itemId == 'dish-ai-1'),
      isTrue,
    );
  });

  test('a recipe that cannot be saved writes nothing at all', () async {
    recipes.failWith = const UnavailableFailure();
    await expectLater(
      saver.save(
        PlanWeekDishFixture.plannedWeek(),
        board: PlanWeekDishFixture.board(),
      ),
      throwsA(isA<UnavailableFailure>()),
    );
    expect(harness.lunch.repository.seeded, isEmpty);
    expect(harness.budgetRepository.setPrices, isEmpty);
    expect(harness.lunch.repository.writtenPicks, isEmpty);
  });

  test('the basket reaches the list under each ingredient’s name, matched to its product', () async {
    final plan = PlanWeekDishFixture.plannedWeek();
    final groceries = ShopWeekGroceries(
      groceryRepository: harness.groceries,
      householdId: Fixtures.householdId,
      memberId: Fixtures.samMemberId,
    );
    final adding = groceries.add([
      for (final line in plan.basket.lines)
        (
          product: plan.basketProduct(line.key)!.product,
          name: plan.shoppingName(line.key),
          quantity: '${line.packs}',
          packs: line.packs,
        ),
    ]);
    await pumpEventQueue();
    harness.groceries.emitItems(const []);
    expect((await adding).where((entry) => entry.isNew), hasLength(2));
    expect(
      harness.groceries.added.map((line) => line.name),
      containsAll(['Wholewheat tortillas', 'Chicken strips']),
    );
    expect(
      harness.groceries.addedMatched.map((line) => line.match.productId),
      containsAll(['tort', 'chick']),
    );
  });

  test('a dish never bought for a box is never saved', () async {
    final board = PlanWeekDishFixture.board();
    final plan = PlanWeekDishFixture.plannedWeek().withPick(
      PlanWeekDishFixture.ayanda,
      LunchFixtures.key(1, LunchSlot.main),
      null,
    );
    final cleared =
        [
          for (var day = 2; day <= 5; day++)
            LunchFixtures.key(day, LunchSlot.main),
        ].fold(
          plan,
          (week, key) => week.withPick(PlanWeekDishFixture.ayanda, key, null),
        );
    await saver.save(cleared, board: board);
    expect(recipes.saved, isEmpty);
  });
}
