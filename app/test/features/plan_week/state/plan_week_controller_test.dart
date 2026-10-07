import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/add_to_checkers/data/checkers_place_resolver.dart';
import 'package:nestprep/features/add_to_checkers/model/checkers_area.dart';
import 'package:nestprep/features/add_to_checkers/model/checkers_shelf.dart';
import 'package:nestprep/features/family_profiles/model/allergen.dart';
import 'package:nestprep/features/lunch_box/model/lunch_slot.dart';
import 'package:nestprep/features/plan_week/data/lunch_week_request.dart';
import 'package:nestprep/features/plan_week/data/shop_week_groceries.dart';
import 'package:nestprep/features/plan_week/model/aisle_shelf.dart';
import 'package:nestprep/features/plan_week/model/idea_search.dart';
import 'package:nestprep/features/plan_week/model/left_out_reason.dart';
import 'package:nestprep/features/plan_week/model/lunch_idea.dart';
import 'package:nestprep/features/plan_week/model/lunch_ideas_reply.dart';
import 'package:nestprep/features/plan_week/model/lunch_week_reply.dart';
import 'package:nestprep/features/plan_week/model/packing_preference.dart';
import 'package:nestprep/features/plan_week/model/plan_fallback.dart';
import 'package:nestprep/features/plan_week/model/shop_week.dart';
import 'package:nestprep/features/plan_week/state/plan_week_controller.dart';
import 'package:nestprep/features/plan_week/state/plan_week_ideas.dart';
import 'package:nestprep/features/plan_week/state/shop_week_saver.dart';
import 'package:nestprep/shared/async/async_state.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:nestprep/shared/money/money.dart';

import '../../../support/checkers_fakes_for_plan_week.dart';
import '../../../support/fake_checkers.dart';
import '../../../support/fake_live_location.dart';
import '../../../support/fake_plan_week.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/lunch_fixtures.dart';
import '../../../support/lunch_planning_harness.dart';

/// *Plan my week from Checkers* step by step (lunch-box ADR-0012): the brief,
/// the model's ideas or the household's usuals, the shop searched idea by
/// idea, the week built and checked, then written and sent to the list.
void main() {
  const lwazi = LunchFixtures.lwaziId;
  const ayanda = LunchFixtures.ayandaId;

  late LunchPlanningHarness harness;
  late FakeLunchIdeaDrafter drafter;
  late FakeLunchWeekBuilder builder;
  late FakeShopCatalogue shop;
  late FakeLunchAisleSource aisle;
  late FakeCheckersAreaPreference areas;
  late FakePackingChoiceStore packingStore;
  late PlanWeekController controller;

  setUp(() async {
    harness = LunchPlanningHarness();
    drafter = FakeLunchIdeaDrafter();
    builder = FakeLunchWeekBuilder();
    shop = FakeShopCatalogue();
    aisle = FakeLunchAisleSource();
    areas = FakeCheckersAreaPreference();
    packingStore = FakePackingChoiceStore();
    controller = PlanWeekController(
      drafter: drafter,
      aisleSource: aisle,
      weekBuilder: builder,
      catalogue: shop,
      placeResolver: CheckersPlaceResolver(
        locationSource: FakeLocationSource(),
        areaPreference: areas,
      ),
      saver: ShopWeekSaver(
        lunchRepository: harness.lunch.repository,
        budgetRepository: harness.budgetRepository,
        householdId: Fixtures.householdId,
        memberId: Fixtures.samMemberId,
      ),
      groceries: ShopWeekGroceries(
        groceryRepository: harness.groceries,
        householdId: Fixtures.householdId,
        memberId: Fixtures.samMemberId,
      ),
      packingStore: packingStore,
      householdId: Fixtures.householdId,
      week: LunchFixtures.week,
    );
    harness.board.addListener(
      () => controller.followBoard(harness.board.board),
    );
    await harness.lunch.arrive();
  });

  tearDown(() async {
    controller.dispose();
    await harness.close();
  });

  LunchIdea idea(
    String id,
    LunchSlot slot,
    String words,
    List<String> children,
  ) => LunchIdea(
    id: id,
    slot: slot,
    idea: words,
    searchTerm: words.toLowerCase(),
    why: '',
    childIds: children,
    excluded: const [],
    origin: IdeaOrigin.drafted,
  );

  test(
    'the brief chooses every child, and the area the phone last chose',
    () async {
      await areas.write(Fixtures.householdId, CheckersArea.durban);
      controller.toggleChild(ayanda);
      expect(controller.childIds, {lwazi});
      controller.toggleChild(ayanda);
      expect(controller.childIds, {lwazi, ayanda});
      await controller.chooseArea(CheckersArea.durban);
      expect(controller.place!.area, CheckersArea.durban);
    },
  );

  test('the lunchbox aisle leads the ideas, the model hears of it, and the '
      'shop is not asked for it again', () async {
    const yoghurtList = CheckersShelf.productList('69d4ebed9cccb04862bcb67f');
    const biscuitList = CheckersShelf.productList('65bb4f576a79cdbcd449b7b7');
    aisle.answer = const [
      AisleShelf(
        title: 'Yoghurt snack time',
        slot: LunchSlot.snack,
        list: yoghurtList,
      ),
      AisleShelf(title: 'Cookies', slot: LunchSlot.treat, list: biscuitList),
    ];
    shop.byShelf[yoghurtList] = [
      planWeekProduct('Fruit yoghurt', id: 'yog', ingredients: 'Milk'),
    ];
    shop.byShelf[biscuitList] = [
      planWeekProduct('Oat cookies', id: 'oat', ingredients: 'Oats, wheat'),
    ];
    drafter.reply = LunchIdeasReply(
      ideas: [
        idea('idea-1', LunchSlot.veg, 'Baby carrots', [lwazi, ayanda]),
      ],
      budgetCents: null,
      callsLeft: 9,
    );

    await controller.draftIdeas();

    expect(controller.ideas.active.map((i) => i.id), [
      'aisle-1',
      'aisle-2',
      'idea-1',
    ]);
    final heard = drafter.aisles.single;
    expect(
      [for (final shelf in heard) shelf.title],
      ['Yoghurt snack time', 'Cookies'],
    );
    expect(heard.first.products, ['Fruit yoghurt']);

    controller.ideas.remove('aisle-2');
    shop.byQuery['baby carrots'] = [
      planWeekProduct(
        'Baby carrots 250g',
        id: 'carrots',
        ingredients: 'Carrots',
      ),
    ];
    await controller.searchStore();

    expect(shop.queries, ['baby carrots']);
    expect(controller.store.searches.map((s) => s.ideaId), [
      'aisle-1',
      'idea-1',
    ]);
    expect(controller.store.isSettled, isTrue);
    final wire = LunchWeekRequest.toWire(
      householdId: Fixtures.householdId,
      week: LunchFixtures.week,
      childIds: controller.childIds,
      searches: controller.store.searches,
      packing: controller.packing.choice,
    );
    final ideas = wire['ideas']! as List<Object?>;
    expect([for (final i in ideas) (i! as Map)['fromAisle']], [true, false]);
  });

  test('without AI the aisle still leads, beside the usuals', () async {
    const yoghurtList = CheckersShelf.productList('69d4ebed9cccb04862bcb67f');
    aisle.answer = const [
      AisleShelf(
        title: 'Yoghurt snack time',
        slot: LunchSlot.snack,
        list: yoghurtList,
      ),
    ];
    shop.byShelf[yoghurtList] = [
      planWeekProduct('Fruit yoghurt', id: 'yog', ingredients: 'Milk'),
    ];
    drafter.failWith = const AiFailure(AiProblem.aiLimitReached);

    await controller.draftIdeas();

    final list = (controller.ideas.state as AsyncData<IdeaList>).value;
    expect(list.source, PlanSource.fallback);
    expect(list.ideas.first.origin, IdeaOrigin.aisle);
  });

  test(
    'a whole run: ideas, the shop live, the week, the write and the list',
    () async {
      drafter.reply = LunchIdeasReply(
        ideas: [
          idea('idea-1', LunchSlot.snack, 'Yoghurt', [lwazi, ayanda]),
          LunchIdea(
            id: 'idea-2',
            slot: LunchSlot.snack,
            idea: 'Peanut butter crackers',
            searchTerm: 'peanut butter crackers',
            why: '',
            childIds: const [],
            excluded: const [
              LeftOutReason(
                LeftOutKind.allergy,
                childId: lwazi,
                allergen: Allergen.peanut,
              ),
            ],
            origin: IdeaOrigin.drafted,
          ),
        ],
        budgetCents: 20000,
        callsLeft: 9,
      );
      shop.byQuery['yoghurt'] = [
        planWeekProduct(
          'Fruit yoghurt 6 x 100g',
          id: 'yog',
          cents: 3600,
          packCount: 6,
          ingredients: 'Milk',
        ),
        planWeekProduct('Mystery pots', id: 'mystery'),
      ];

      await controller.draftIdeas();
      expect(controller.step, PlanWeekStep.ideas);
      expect(controller.ideas.active.map((i) => i.id), ['idea-1']);

      controller.addOwnIdea(LunchSlot.fruit, 'Apples');
      shop.byQuery['Apples'] = [
        planWeekProduct(
          'Apples 6 pack',
          id: 'apples',
          cents: 2400,
          packCount: 6,
          ingredients: 'Apples',
        ),
      ];
      builder.reply = LunchWeekReply(
        lunches: [
          const ReplyLunch(
            childId: lwazi,
            day: 2,
            slot: LunchSlot.snack,
            ideaId: 'idea-1',
            productId: 'yog',
          ),
          const ReplyLunch(
            childId: ayanda,
            day: 2,
            slot: LunchSlot.snack,
            ideaId: 'idea-1',
            productId: 'yog',
          ),
        ],
        boxesPerPack: const {'yog': 6},
        budgetCents: 20000,
        dropped: 0,
        callsLeft: 8,
      );
      await controller.searchStore();
      // Straight on to the week once the shop settles.
      expect(controller.step, PlanWeekStep.week);
      // The struck-out idea is never searched.
      expect(shop.queries, ['yoghurt', 'Apples']);
      final yoghurt = controller.store.searches.first;
      expect(yoghurt.status, IdeaSearchStatus.done);
      expect(yoghurt.kept.map((p) => p.productId), ['yog', 'mystery']);
      // No allergen information, and Lwazi has allergies: Ayanda's only.
      expect(yoghurt.found.last.childIds, {ayanda});

      final week = (controller.shop.state as AsyncData<ShopWeek>).value;
      expect(week.pickCount, 2);
      expect(week.basket.total, const Money(3600));
      expect(week.budget, const Money(20000));

      await controller.use();
      expect(controller.step, PlanWeekStep.done);
      final added = harness.lunch.repository.addedItems.single;
      expect(added.name, 'Fruit yoghurt 6 x 100g');
      expect(added.slot, LunchSlot.snack);
      expect(added.allergens, ['milk']);
      final price = harness.budgetRepository.setPrices.single;
      expect((price.itemId, price.cents, price.portions), ('item-1', 3600, 6));
      expect(harness.lunch.repository.writtenPicks, hasLength(2));
      expect(controller.shop.saved!.lunches, 2);

      final adding = controller.shop.addToGroceries((packs) => '$packs pack');
      await pumpEventQueue();
      harness.groceries.emitItems(const []);
      await adding;
      expect(harness.groceries.added.single.quantity, '1 pack');
      expect(harness.groceries.matchesSet.single.match.productId, 'yog');
      expect(controller.shop.groceriesAdded, 1);
    },
  );

  test('without AI the ideas are the household usuals, said so', () async {
    drafter.failWith = const AiFailure(AiProblem.aiLimitReached);
    await controller.draftIdeas();
    final list =
        (controller.ideas.state
                as AsyncData<
                  ({
                    List<LunchIdea> ideas,
                    PlanSource source,
                    PlanFallbackReason? reason,
                    int? callsLeft,
                  })
                >)
            .value;
    expect(list.source, PlanSource.fallback);
    expect(list.reason, PlanFallbackReason.aiLimitReached);
    expect(list.ideas, isNotEmpty);
    expect(list.ideas.every((i) => i.origin == IdeaOrigin.usual), isTrue);
    // Peanut butter is never one of Lwazi's usuals.
    expect(
      list.ideas
          .where((i) => i.idea.contains('Peanut'))
          .every((i) => !i.childIds.contains(lwazi)),
      isTrue,
    );
  });

  test('a refusal that is not about AI is said, not hidden', () async {
    drafter.failWith = const PlanWeekFailure(PlanWeekProblem.weekNotPlannable);
    await controller.draftIdeas();
    expect(controller.ideas.state, isA<AsyncFailure<Object?>>());
  });

  test('a failed search is passed over when something else was kept', () async {
    drafter.reply = LunchIdeasReply(
      ideas: [
        idea('idea-1', LunchSlot.fruit, 'Grapes', [ayanda]),
        idea('idea-2', LunchSlot.snack, 'Rusks', [ayanda]),
      ],
      budgetCents: null,
      callsLeft: null,
    );
    shop.failFor['grapes'] = const CheckersFailure(
      CheckersProblem.catalogueBusy,
    );
    shop.byQuery['rusks'] = [planWeekProduct('Rusks', ingredients: 'Oats')];
    await controller.draftIdeas();
    await controller.searchStore();
    expect(controller.step, PlanWeekStep.week);
    expect(controller.store.searches.first.status, IdeaSearchStatus.failed);
    expect(builder.sent.single, hasLength(2));
  });

  test('a shop run that kept nothing stays at the shop, and goes back to '
      'the ideas', () async {
    drafter.reply = LunchIdeasReply(
      ideas: [
        idea('idea-1', LunchSlot.fruit, 'Grapes', [ayanda]),
      ],
      budgetCents: null,
      callsLeft: null,
    );
    shop.failFor['grapes'] = const CheckersFailure(
      CheckersProblem.catalogueBusy,
    );
    await controller.draftIdeas();
    await controller.searchStore();
    expect(controller.step, PlanWeekStep.store);
    expect(controller.store.isSettled, isTrue);
    expect(controller.store.hasKept, isFalse);
    expect(builder.sent, isEmpty);
    controller.back();
    expect(controller.step, PlanWeekStep.ideas);
    expect(controller.ideas.active, hasLength(1));
  });

  test('the week is built on the phone when the model cannot help', () async {
    drafter.reply = LunchIdeasReply(
      ideas: [
        idea('idea-1', LunchSlot.fruit, 'Grapes', [ayanda]),
      ],
      budgetCents: null,
      callsLeft: null,
    );
    shop.byQuery['grapes'] = [planWeekProduct('Grapes', ingredients: 'Grapes')];
    builder.failWith = const UnavailableFailure();
    await controller.draftIdeas();
    await controller.searchStore(budget: const Money(5000));
    final week = (controller.shop.state as AsyncData<ShopWeek>).value;
    expect(week.source, PlanSource.fallback);
    expect(week.fallbackReason, PlanFallbackReason.offline);
    expect(week.budget, const Money(5000));
    // Ayanda's five fruit compartments.
    expect(
      week.children.firstWhere((c) => c.childId == ayanda).added,
      hasLength(5),
    );
  });

  test('back from the week is the ideas, the shop forgotten; start over '
      'forgets everything', () async {
    drafter.reply = LunchIdeasReply(
      ideas: [
        idea('idea-1', LunchSlot.fruit, 'Grapes', [ayanda]),
      ],
      budgetCents: null,
      callsLeft: null,
    );
    shop.byQuery['grapes'] = [planWeekProduct('Grapes', ingredients: 'Grapes')];
    await controller.draftIdeas();
    await controller.searchStore();
    expect(controller.step, PlanWeekStep.week);
    controller.back();
    expect(controller.step, PlanWeekStep.ideas);
    expect(controller.ideas.active, hasLength(1));
    expect(controller.store.searches, isEmpty);
    expect(controller.shop.state, isA<AsyncLoading<Object?>>());
    controller.startOver();
    expect(controller.step, PlanWeekStep.brief);
    expect(controller.ideas.state, isA<AsyncLoading<Object?>>());
  });

  group('the packing choices', () {
    test('reach the model, and the phone fills only the chosen '
        'compartments without it', () async {
      controller.packing
        ..togglePreference(PackingPreference.favourPrice)
        ..toggleSlot(LunchSlot.main)
        ..toggleSlot(LunchSlot.snack)
        ..toggleSlot(LunchSlot.veg)
        ..toggleSlot(LunchSlot.treat);
      drafter.failWith = const AiFailure(AiProblem.aiLimitReached);
      await controller.draftIdeas();
      expect(drafter.packed.single.preferences, {
        PackingPreference.favourPrice,
      });
      expect(drafter.packed.single.slots, {LunchSlot.fruit});
      final usuals = controller.ideas.active;
      expect(usuals, isNotEmpty);
      expect(usuals.every((i) => i.slot == LunchSlot.fruit), isTrue);

      for (final usual in usuals) {
        shop.byQuery[usual.searchTerm] = [
          planWeekProduct(usual.idea, id: usual.id, ingredients: usual.idea),
        ];
      }
      builder.failWith = const UnavailableFailure();
      await controller.searchStore();
      expect(builder.packed.single.slots, {LunchSlot.fruit});
      final week = (controller.shop.state as AsyncData<ShopWeek>).value;
      expect(week.slots, {LunchSlot.fruit});
      for (final child in week.children) {
        expect(
          child.added.keys.every((k) => k.endsWith(LunchSlot.fruit.name)),
          isTrue,
        );
      }
    });
  });
}
