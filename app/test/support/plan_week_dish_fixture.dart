import 'package:nestprep/features/family_profiles/model/food_rules.dart';
import 'package:nestprep/features/lunch_box/model/lunch_board.dart';
import 'package:nestprep/features/lunch_box/model/lunch_budget_week.dart';
import 'package:nestprep/features/lunch_box/model/lunch_item.dart';
import 'package:nestprep/features/lunch_box/model/lunch_plan.dart';
import 'package:nestprep/features/lunch_box/model/lunch_slot.dart';
import 'package:nestprep/features/plan_week/model/checked_product.dart';
import 'package:nestprep/features/plan_week/model/dish_draft.dart';
import 'package:nestprep/features/plan_week/model/idea_search.dart';
import 'package:nestprep/features/plan_week/model/ingredient_find.dart';
import 'package:nestprep/features/plan_week/model/lunch_idea.dart';
import 'package:nestprep/features/plan_week/model/lunch_week_reply.dart';
import 'package:nestprep/features/plan_week/model/shop_week.dart';
import 'package:nestprep/features/plan_week/model/shop_week_assembly.dart';
import 'package:nestprep/shared/money/money.dart';

import 'checkers_fakes_for_plan_week.dart';
import 'lunch_fixtures.dart';
import 'plan_week_packing.dart';

/// One AI main as a dish (lunch-box ADR-0021) for Ayanda, a week of it:
/// a wholewheat wrap bought as an eight-pack of tortillas (R30) and a
/// four-box pack of chicken strips (R60). Five wraps cost R150.
abstract final class PlanWeekDishFixture {
  static const ayanda = LunchFixtures.ayandaId;

  static Map<String, FoodRules> get rules => {
    ayanda: LunchFixtures.ayandaEntry.foodRules,
  };

  static Map<String, Object?> recipeWire({List<Object?>? allergens}) => {
    'name': 'Mexican wholewheat wrap',
    'summary': 'Chicken and corn in a soft wrap.',
    'ingredients': [
      {
        'name': 'Wholewheat tortillas',
        'quantity': 1,
        'unit': null,
        'searchTerm': 'wholewheat tortillas',
      },
      {
        'name': 'Chicken strips',
        'quantity': 50,
        'unit': 'g',
        'searchTerm': 'chicken strips',
      },
    ],
    'steps': ['Warm the tortilla.', 'Fill and roll.'],
    'prepMinutes': 10,
    'prepAhead': true,
    'prepNote': 'Roll it the night before.',
    'allergens': allergens ?? ['wheat'],
  };

  static DishDraft get draft => DishDraft.fromWire(recipeWire())!;

  static final tortillas = planWeekProduct(
    'Mexicorn Wholewheat Tortillas 8 Pack',
    id: 'tort',
    cents: 3000,
    ingredients: 'Wheat flour, soya lecithin, salt',
    packCount: 8,
  );
  static final chicken = planWeekProduct(
    'Chicken Strips 400g',
    id: 'chick',
    cents: 6000,
    ingredients: 'Chicken',
  );

  static LunchIdea get idea => LunchIdea(
    id: 'idea-1',
    slot: LunchSlot.main,
    idea: 'Mexican whole wheat wrap',
    searchTerm: 'wholewheat tortillas',
    why: '',
    childIds: const [ayanda],
    excluded: const [],
    origin: IdeaOrigin.drafted,
    dish: draft,
  );

  static IdeaSearch get search {
    final dish = draft;
    return IdeaSearch(
      idea: idea,
      status: IdeaSearchStatus.done,
      ingredients: [
        IngredientFind(
          ingredient: dish.ingredients[0],
          found: [CheckedProduct.of(tortillas, rules)],
        ),
        IngredientFind(
          ingredient: dish.ingredients[1],
          found: [CheckedProduct.of(chicken, rules)],
        ),
      ],
    );
  }

  /// The board on the Saturday before the week: no school day has gone.
  static LunchBoard board([
    List<LunchPlan> plans = const [],
    List<LunchItem>? items,
  ]) => LunchBoard.from(
    week: LunchFixtures.week,
    today: LunchFixtures.week.monday.addDays(-2),
    roster: LunchFixtures.roster(),
    library: items ?? LunchFixtures.library,
    favourites: const [],
    plans: plans,
  );

  /// The server's week: the wrap Monday to Friday for Ayanda.
  static LunchWeekReply get reply => LunchWeekReply.fromWire({
    'lunches': [
      for (var day = 1; day <= 5; day++)
        {
          'childId': ayanda,
          'day': day,
          'slot': 'main',
          'ideaId': 'idea-1',
          'productId': 'dish:idea-1',
        },
    ],
    'packs': [
      {'productId': 'tort', 'boxesPerPack': 8},
      {'productId': 'chick', 'boxesPerPack': 4},
    ],
    'dishes': [
      {
        'ideaId': 'idea-1',
        'parts': [
          {'ingredient': 'Wholewheat tortillas', 'productId': 'tort'},
          {'ingredient': 'Chicken strips', 'productId': 'chick'},
        ],
      },
    ],
  });

  static ShopWeek plannedWeek({LunchBoard? on, LunchBudgetWeek? weekSoFar}) =>
      ShopWeekAssembly.fromReply(
        board: on ?? board(),
        childIds: {ayanda},
        searches: [search],
        reply: reply,
        budget: const Money(50000),
        packing: packingFor({LunchSlot.main}),
        weekSoFar: weekSoFar,
      );
}
