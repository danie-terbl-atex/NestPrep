import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/family_profiles/model/allergen.dart';
import 'package:nestprep/features/lunch_box/model/fill_week_box.dart';
import 'package:nestprep/features/lunch_box/model/lunch_board.dart';
import 'package:nestprep/features/lunch_box/model/lunch_item.dart';
import 'package:nestprep/features/lunch_box/model/lunch_pick.dart';
import 'package:nestprep/features/lunch_box/model/lunch_plan.dart';
import 'package:nestprep/features/lunch_box/model/lunch_slot.dart';
import 'package:nestprep/features/lunch_box/model/lunch_starter_box.dart';
import 'package:nestprep/features/lunch_box/state/lunch_library_items.dart';
import 'package:nestprep/features/lunch_box/state/starter_box_items.dart';

import '../../../support/fake_lunch_repository.dart';
import '../../../support/fake_starter_boxes.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/lunch_fixtures.dart';

/// A ready-made box's picks made real before they are written (lunch-box
/// ADR-0020 §5): a recipe becomes `recipe-<id>`, a quick pick the starter
/// library's own `seed-<key>`, the household's copy reused or put back out,
/// and each pick carries every code anyone named.
void main() {
  const wrapItemId = 'recipe-${StarterBoxFixtures.wrapId}';

  late FakeLunchRepository lunches;
  late StarterBoxItems items;

  setUp(() {
    lunches = FakeLunchRepository();
    items = StarterBoxItems(
      library: LunchLibraryItems(
        lunchRepository: lunches,
        householdId: Fixtures.householdId,
      ),
    );
  });

  tearDown(() => lunches.close());

  LunchBoard board({List<LunchItem> extra = const []}) => LunchBoard.from(
    week: LunchFixtures.week,
    today: LunchFixtures.week.monday.addDays(-2),
    roster: LunchFixtures.roster(),
    library: [...LunchFixtures.library, ...extra],
    favourites: const [],
    plans: const [],
  );

  FillWeekBox boxOf(LunchStarterBox box, LunchBoard on) =>
      FillWeekBox.readyMade(
        box,
        recipes: {
          for (final recipe in StarterBoxFixtures.recipes) recipe.id: recipe,
        },
        rules: on.childWeek(LunchFixtures.ayandaId)!.child.foodRules,
        library: on.libraryById,
        addedBy: Fixtures.samMemberId,
      );

  /// Friday's picks from [box]: every compartment, the treat included.
  Future<Map<String, LunchPick>> ensureFriday(
    LunchStarterBox box,
    LunchBoard on,
  ) {
    final fill = boxOf(box, on);
    return items.ensure(
      {
        for (final MapEntry(key: slot, value: pick)
            in fill.packsOn(DateTime.friday).entries)
          LunchPlan.slotKey(DateTime.friday, slot): pick,
      },
      candidates: fill.candidates,
      board: on,
    );
  }

  Map<String, LunchItem> seeded() => {
    for (final batch in lunches.seeded)
      for (final item in batch) item.id: item,
  };

  test(
    'a recipe becomes recipe-<id>, named and prepped as the recipe says, '
    'carrying its id and every allergen the box and the recipe name',
    () async {
      final picks = await ensureFriday(StarterBoxFixtures.classic, board());
      final wrap = seeded()[wrapItemId]!;
      expect(wrap.recipeId, StarterBoxFixtures.wrapId);
      expect(wrap.slot, LunchSlot.main);
      expect(wrap.knownAllergens, {Allergen.wheat, Allergen.sesame});
      final muffin = seeded()['recipe-${StarterBoxFixtures.muffinId}']!;
      expect(muffin.prepAhead, isTrue);
      expect(muffin.prepNote, StarterBoxFixtures.muffin.prepNote);
      expect(muffin.knownAllergens, contains(Allergen.milk));
      final main = picks[LunchFixtures.key(5, LunchSlot.main)]!;
      expect(main.itemId, wrapItemId);
      expect(main.knownAllergens, contains(Allergen.sesame));
    },
  );

  test('a quick pick is the starter library\'s own item, with the '
      'catalogue\'s name and codes', () async {
    await ensureFriday(StarterBoxFixtures.crunch, board());
    final rolls = seeded()['seed-cheese-rolls']!;
    expect(rolls.seedKey, 'cheese-rolls');
    expect(rolls.recipeId, isNull);
    expect(rolls.knownAllergens, {Allergen.wheat, Allergen.milk});
  });

  test('an item the household put away is put back out, not written '
      'again', () async {
    final putAway = LunchFixtures.item(
      'seed-grapes',
      'Grapes',
      LunchSlot.fruit,
      archived: true,
    );
    final picks = await ensureFriday(
      StarterBoxFixtures.crunch,
      board(extra: [putAway]),
    );
    expect(lunches.archived, [(itemId: 'seed-grapes', archived: false)]);
    expect(seeded().keys, isNot(contains('seed-grapes')));
    expect(picks[LunchFixtures.key(5, LunchSlot.fruit)]!.itemId, 'seed-grapes');
  });

  test('the household\'s own copy is used as it is, with any allergen it '
      'added kept on the pick', () async {
    final theirs = LunchFixtures.item(
      wrapItemId,
      'Hummus wrap, our way',
      LunchSlot.main,
      allergens: {Allergen.wheat, Allergen.milk},
    );
    final picks = await ensureFriday(
      StarterBoxFixtures.classic,
      board(extra: [theirs]),
    );
    expect(seeded().keys, isNot(contains(wrapItemId)));
    final pick = picks[LunchFixtures.key(5, LunchSlot.main)]!;
    expect(pick.name, 'Hummus wrap, our way');
    expect(pick.knownAllergens, {
      Allergen.wheat,
      Allergen.milk,
      Allergen.sesame,
    });
  });

  test('a pick from the household\'s own library passes as it is, and an '
      'item used twice is written once', () async {
    final on = board();
    final fill = boxOf(StarterBoxFixtures.classic, on);
    final picks = await items.ensure(
      {
        LunchFixtures.key(1, LunchSlot.veg): LunchPick.of(
          LunchFixtures.carrots,
        ),
        for (var day = 1; day <= 2; day++)
          LunchFixtures.key(day, LunchSlot.main): fill.packsOn(
            day,
          )[LunchSlot.main]!,
      },
      candidates: fill.candidates,
      board: on,
    );
    expect(picks[LunchFixtures.key(1, LunchSlot.veg)]!.itemId, 'carrots');
    expect(lunches.seeded, hasLength(1));
  });
}
