import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/async/async_state.dart';
import '../../add_to_checkers/data/checkers_place_resolver.dart';
import '../../add_to_checkers/data/retailer_catalogues.dart';
import '../../family_profiles/model/food_rules.dart';
import '../../lunch_box/model/lunch_board.dart';
import '../../lunch_box/model/lunch_budget_week.dart';
import '../../lunch_box/model/lunch_slot.dart';
import '../../lunch_box/model/lunch_week.dart';
import '../data/lunch_aisle_source.dart';
import '../data/lunch_idea_drafter.dart';
import '../data/lunch_week_builder.dart';
import '../data/packing_choice_store.dart';
import '../data/shop_week_groceries.dart';
import '../model/lunch_idea.dart';
import 'lunch_shop_choice.dart';
import 'plan_week_aisle.dart';
import 'plan_week_ideas.dart';
import 'plan_week_packing.dart';
import 'plan_week_place.dart';
import 'plan_week_retailer.dart';
import 'plan_week_shop.dart';
import 'plan_week_step.dart';
import 'shop_week_saver.dart';
import 'store_search_run.dart';

export 'plan_week_step.dart';

/// *Plan my week*: the brief, the lunchbox aisle and the ideas, the shop,
/// the week, and using it. This holds which step is showing and whose
/// lunches; each step's own state is its part's — [retailer], [places],
/// [packing], [aisle], [ideas], [store], [shop]. It follows the lunch board for the children, their rules and the
/// library, so every check is against what the phone holds now. Nothing is
/// written before *Use this week*.
final class PlanWeekController extends ChangeNotifier {
  PlanWeekController({
    required LunchIdeaDrafter drafter,
    required LunchAisleSource aisleSource,
    required LunchWeekBuilder weekBuilder,
    required RetailerCatalogues catalogues,
    required LunchShopChoice shopChoice,
    required bool Function() isPnpOn,
    required CheckersPlaceResolver placeResolver,
    required ShopWeekSaver saver,
    required ShopWeekGroceries groceries,
    required PackingChoiceStore packingStore,
    required this.householdId,
    required this.week,
  }) : _shopChoice = shopChoice {
    retailer = PlanWeekRetailer(
      catalogues: catalogues,
      choice: shopChoice,
      isPnpOn: isPnpOn,
    );
    shopChoice.addListener(_changed);
    places = PlanWeekPlace(
      resolver: placeResolver,
      householdId: householdId,
      onChange: _changed,
    );
    packing = PlanWeekPacking(
      store: packingStore,
      householdId: householdId,
      onChange: _changed,
    );
    aisle = PlanWeekAisle(source: aisleSource, onChange: _changed);
    ideas = PlanWeekIdeas(drafter: drafter, onChange: _changed);
    store = StoreSearchRun(onChange: _changed);
    shop = PlanWeekShop(
      builder: weekBuilder,
      saver: saver,
      groceries: groceries,
      onChange: _changed,
    );
    unawaited(places.restore());
    unawaited(packing.restore());
  }

  final String householdId;
  final LunchWeek week;
  final LunchShopChoice _shopChoice;
  late final PlanWeekRetailer retailer;
  late final PlanWeekPlace places;
  late final PlanWeekPacking packing;
  late final PlanWeekAisle aisle;
  late final PlanWeekIdeas ideas;
  late final StoreSearchRun store;
  late final PlanWeekShop shop;

  AsyncState<LunchBoard> _board = const AsyncLoading();
  PlanWeekStep _step = PlanWeekStep.brief;
  Set<String>? _childIds;
  LunchBudgetWeek? _budgetWeek;
  var _isDisposed = false;

  AsyncState<LunchBoard> get board => _board;
  PlanWeekStep get step => _step;

  /// Every child chosen, until somebody says otherwise.
  Set<String> get childIds =>
      _childIds ??
      switch (_board) {
        AsyncData(:final value) => {
          for (final child in value.children) child.childId,
        },
        _ => const {},
      };

  void followBoard(AsyncState<LunchBoard> board) {
    if (identical(board, _board)) return;
    _board = board;
    _changed();
  }

  void toggleChild(String childId) {
    final chosen = {...childIds};
    if (!chosen.remove(childId)) chosen.add(childId);
    _childIds = chosen;
    _changed();
  }

  /// Brief → ideas: the lunchbox aisle near the household, then the model's
  /// ideas for what it lacks (lunch-box ADR-0013).
  Future<void> draftIdeas() async {
    final board = _latestBoard;
    if (board == null || childIds.isEmpty) return;
    _step = PlanWeekStep.ideas;
    ideas.clear();
    retailer.begin();
    final place = await places.resolvedOrFallback();
    await aisle.read(
      shop: retailer.shop,
      catalogue: retailer.catalogue,
      near: place.coordinates,
      rulesByChild: rulesByChild,
      slots: packing.plannedSlots,
    );
    if (_step != PlanWeekStep.ideas) return;
    await ideas.draft(
      householdId: householdId,
      week: week,
      board: board,
      childIds: childIds,
      packing: packing.choice,
      aisle: aisle.shelves,
      aisleForModel: aisle.forModel,
    );
  }

  void addOwnIdea(LunchSlot slot, String text) =>
      ideas.addOwn(slot, text, rulesByChild);

  /// Ideas → the shop → the week: every idea still for a child searched in
  /// turn (the aisle's shelves are answered already), then the week built
  /// from what was kept, read against [budgetWeek] — budget mode's picture
  /// of the household's week as this phone last heard it.
  Future<void> searchStore({LunchBudgetWeek? budgetWeek}) async {
    final active = ideas.active;
    if (active.isEmpty) return;
    final place = await places.resolved();
    final kept = {for (final idea in active) idea.id};
    _budgetWeek = budgetWeek;
    _step = PlanWeekStep.store;
    await store.start(
      catalogue: retailer.catalogue,
      ideas: [
        for (final idea in active)
          if (idea.origin != IdeaOrigin.aisle) idea,
      ],
      answered: [
        for (final shelf in aisle.shelves)
          if (kept.contains(shelf.ideaId)) shelf,
      ],
      near: place.coordinates,
      rulesByChild: rulesByChild,
    );
    if (_step != PlanWeekStep.store) return;
    await buildWeek();
  }

  /// The week from what the shop had — again, after a failure.
  Future<void> buildWeek() async {
    final board = _latestBoard;
    if (board == null || !store.hasKept || !store.isSettled) return;
    _step = PlanWeekStep.week;
    await shop.build(
      householdId: householdId,
      week: week,
      board: board,
      childIds: childIds,
      searches: store.searches,
      packing: packing.choice,
      budgetWeek: _budgetWeek,
    );
  }

  /// The week → done.
  Future<void> use() async {
    final board = _latestBoard;
    if (board == null) return;
    if (await shop.use(board)) {
      _step = PlanWeekStep.done;
      _changed();
    }
  }

  /// One step back, keeping what the earlier step held.
  void back() {
    final previous = _step.previous;
    if (previous.index < PlanWeekStep.ideas.index) {
      aisle.clear();
      ideas.clear();
      retailer.end();
    }
    if (previous.index < PlanWeekStep.store.index) store.clear();
    if (previous.index < PlanWeekStep.week.index) shop.clear();
    _step = previous;
    _changed();
  }

  void startOver() {
    aisle.clear();
    ideas.clear();
    store.clear();
    shop.clear();
    retailer.end();
    _step = PlanWeekStep.brief;
    _changed();
  }

  /// The chosen children's food rules, as the phone holds them now.
  Map<String, FoodRules> get rulesByChild => {
    for (final child in _latestBoard?.children ?? const <LunchChildWeek>[])
      if (childIds.contains(child.childId))
        child.childId: child.child.foodRules,
  };

  LunchBoard? get _latestBoard => switch (_board) {
    AsyncData(:final value) => value,
    _ => null,
  };

  void _changed() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _shopChoice.removeListener(_changed);
    aisle.clear();
    ideas.clear();
    store.clear();
    shop.clear();
    super.dispose();
  }
}
