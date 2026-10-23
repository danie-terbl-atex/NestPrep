import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/family_profiles/model/allergen.dart';
import 'package:nestprep/features/lunch_box/model/lunch_budget.dart';
import 'package:nestprep/features/lunch_box/model/lunch_budget_week.dart';
import 'package:nestprep/features/lunch_box/model/lunch_item.dart';
import 'package:nestprep/features/lunch_box/model/lunch_pick.dart';
import 'package:nestprep/features/lunch_box/model/lunch_plan.dart';
import 'package:nestprep/features/lunch_box/model/lunch_price.dart';
import 'package:nestprep/features/lunch_box/model/lunch_slot.dart';
import 'package:nestprep/features/lunch_box/model/lunch_week_cost.dart';
import 'package:nestprep/features/plan_week/data/lunch_week_request.dart';
import 'package:nestprep/features/plan_week/model/dish_draft.dart';
import 'package:nestprep/features/plan_week/model/lunch_ideas_reply.dart';
import 'package:nestprep/shared/money/money.dart';

import '../../../support/lunch_fixtures.dart';
import '../../../support/plan_week_dish_fixture.dart';
import '../../../support/plan_week_packing.dart';

/// An AI main is a dish (lunch-box ADR-0021): its recipe arrives with the
/// idea, its ingredients are searched and sent, the week places it and buys
/// it as its ingredients — fillings included — and the plan reads the same
/// total the meter will once it is used.
void main() {
  const ayanda = PlanWeekDishFixture.ayanda;
  String key(int day, LunchSlot slot) => LunchPlan.slotKey(day, slot);
  const recipeWire = PlanWeekDishFixture.recipeWire;

  group('the dish arrives with its idea', () {
    test('a main idea carries its recipe, one box’s worth', () {
      final reply = LunchIdeasReply.fromWire({
        'ideas': [
          {
            'id': 'idea-1',
            'slot': 'main',
            'idea': 'Mexican whole wheat wrap',
            'searchTerm': 'wholewheat tortillas',
            'childIds': [ayanda],
            'recipe': recipeWire(),
          },
          {
            'id': 'idea-2',
            'slot': 'snack',
            'idea': 'Rice cakes',
            'searchTerm': 'rice cakes',
            'childIds': [ayanda],
            'recipe': recipeWire(),
          },
        ],
      });
      final dish = reply.ideas.first.dish!;
      expect(dish.name, 'Mexican wholewheat wrap');
      expect(dish.allergens, {Allergen.wheat});
      expect(dish.ingredients[1].unitCode, 'g');
      expect(dish.toRecipe().servings, 1);
      expect(dish.toRecipe().isAiDrafted, isTrue);
      expect(reply.ideas.last.dish, isNull, reason: 'only a main is a dish');
    });

    test('a recipe with a code this build cannot check is no dish — never read as safe', () {
      expect(DishDraft.fromWire(recipeWire(allergens: ['lupin'])), isNull);
      expect(
        DishDraft.fromWire({...recipeWire(), 'steps': <Object?>[]}),
        isNull,
      );
      expect(DishDraft.fromWire('a wrap'), isNull);
    });
  });

  // The dish's ingredients as the shop answered them.
  final dishSearch = PlanWeekDishFixture.search;

  test(
    'is sent with each ingredient’s products, even with no product idea kept',
    () {
      final wire = LunchWeekRequest.toWire(
        householdId: 'h1',
        week: LunchFixtures.week,
        childIds: {ayanda},
        searches: [dishSearch],
        packing: packingFor(const {LunchSlot.main}),
      );
      final ideas = wire['ideas']! as List<Object?>;
      expect(ideas, hasLength(1));
      expect(ideas.single, containsPair('products', isEmpty));
      final dish = (ideas.single! as Map<String, Object?>)['dish']!;
      expect(dish, containsPair('name', 'Mexican wholewheat wrap'));
      final lines =
          (dish as Map<String, Object?>)['ingredients']! as List<Object?>;
      expect(
        [for (final line in lines) (line! as Map<String, Object?>)['name']],
        ['Wholewheat tortillas', 'Chicken strips'],
      );
    },
  );

  const board = PlanWeekDishFixture.board;
  const plannedWeek = PlanWeekDishFixture.plannedWeek;

  test(
    'the week places the dish and buys its fillings, not only the tortillas',
    () {
      final plan = plannedWeek();
      expect(plan.pickCount, 5);
      final pick = plan.children.single.added[key(1, LunchSlot.main)]!;
      expect(plan.dishOf(pick)?.draft.name, 'Mexican wholewheat wrap');
      // Five wraps: one pack of eight tortillas, two packs of four chicken.
      expect(plan.basket.lineFor('tort')?.packs, 1);
      expect(plan.basket.lineFor('chick')?.packs, 2);
      expect(plan.basket.total, const Money(3000 + 2 * 6000));
      expect(plan.shoppingName('chick'), 'Chicken strips');
    },
  );

  test('reads the same total the meter shows once the dish is used', () {
    final before = board();
    final plan = plannedWeek(
      weekSoFar: LunchBudgetWeek(
        board: before,
        prices: const {},
        budget: const LunchBudget(id: 'weekly', cents: 50000, updatedBy: 'm'),
      ),
    );
    final dishItem = LunchItem.named(
      id: 'dish-ai-1',
      name: 'Mexican wholewheat wrap',
      slot: LunchSlot.main,
      allergens: const {Allergen.wheat},
      addedBy: 'm',
      householdRecipeId: 'ai-1',
    );
    final after = board(
      [
        LunchFixtures.plan(
          ayanda,
          slots: {
            for (var day = 1; day <= 5; day++)
              key(day, LunchSlot.main): LunchPick.of(dishItem),
          },
        ),
      ],
      [...LunchFixtures.library, dishItem],
    );
    final dish = plan.dishes['idea-1']!;
    final meter = LunchWeekCost.of(
      board: after,
      prices: {
        'dish-ai-1': LunchPrice(
          id: 'dish-ai-1',
          cents: dish.costFor(5, plan.boxesPerPackOf).cents,
          portions: 5,
          updatedBy: 'm',
        ),
      },
    );
    expect(plan.reading!.spent, const Money(15000));
    expect(plan.reading!.spent, meter.basket.total);
  });
}
