import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/async/async_state.dart';
import '../../../shared/failure/app_failure.dart';
import '../../../shared/money/money.dart';
import '../../add_to_checkers/data/checkers_catalogue.dart';
import '../../add_to_checkers/data/checkers_place_resolver.dart';
import '../../add_to_checkers/model/checkers_area.dart';
import '../../add_to_checkers/model/checkers_place.dart';
import '../../family_profiles/model/food_rules.dart';
import '../../lunch_box/model/lunch_board.dart';
import '../../lunch_box/model/lunch_slot.dart';
import '../../lunch_box/model/lunch_week.dart';
import '../data/lunch_aisle_source.dart';
import '../data/lunch_idea_drafter.dart';
import '../data/lunch_week_builder.dart';
import '../data/shop_week_groceries.dart';
import '../model/lunch_idea.dart';
import 'plan_week_aisle.dart';
import 'plan_week_ideas.dart';
import 'plan_week_shop.dart';
import 'shop_week_saver.dart';
import 'store_search_run.dart';

/// The five steps of *Plan my week* (lunch-box ADR-0012), each confirmed
/// before the next.
enum PlanWeekStep { brief, ideas, store, week, done }

/// *Plan my week from Checkers*: the brief, the lunchbox aisle and the
/// ideas, the shop, the week, and using it. This holds which step is
/// showing, whose lunches and which shop; each step's own state is its
/// part's — [aisle], [ideas], [store], [shop]. It
/// follows the lunch board for the children, their rules and the library, so
/// every check is against what the phone holds now. Nothing is written
/// before *Use this week*.
final class PlanWeekController extends ChangeNotifier {
  PlanWeekController({
    required LunchIdeaDrafter drafter,
    required LunchAisleSource aisleSource,
    required LunchWeekBuilder weekBuilder,
    required CheckersCatalogue catalogue,
    required CheckersPlaceResolver placeResolver,
    required ShopWeekSaver saver,
    required ShopWeekGroceries groceries,
    required this.householdId,
    required this.week,
  }) : _places = placeResolver {
    aisle = PlanWeekAisle(
      source: aisleSource,
      catalogue: catalogue,
      onChange: _changed,
    );
    ideas = PlanWeekIdeas(drafter: drafter, onChange: _changed);
    store = StoreSearchRun(catalogue: catalogue, onChange: _changed);
    shop = PlanWeekShop(
      builder: weekBuilder,
      saver: saver,
      groceries: groceries,
      onChange: _changed,
    );
    unawaited(_resolvePlace());
  }

  final CheckersPlaceResolver _places;
  final String householdId;
  final LunchWeek week;
  late final PlanWeekAisle aisle;
  late final PlanWeekIdeas ideas;
  late final StoreSearchRun store;
  late final PlanWeekShop shop;

  AsyncState<LunchBoard> _board = const AsyncLoading();
  PlanWeekStep _step = PlanWeekStep.brief;
  Set<String>? _childIds;
  CheckersPlace? _place;
  var _isDisposed = false;

  AsyncState<LunchBoard> get board => _board;
  PlanWeekStep get step => _step;

  /// Where the shop is searched; null until it is known.
  CheckersPlace? get place => _place;

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

  Future<void> chooseArea(CheckersArea area) async {
    await _places.choose(householdId, area);
    _place = CheckersPlace.area(area);
    _changed();
  }

  /// Brief → ideas: the lunchbox aisle's shelves near the household, then
  /// the model's ideas for what they lack (lunch-box ADR-0013).
  Future<void> draftIdeas() async {
    final board = _latestBoard;
    if (board == null || childIds.isEmpty) return;
    _go(PlanWeekStep.ideas);
    ideas.clear();
    final place = _place ??= await _placeOrFallback();
    await aisle.read(near: place.coordinates, rulesByChild: rulesByChild);
    if (_step != PlanWeekStep.ideas) return;
    await ideas.draft(
      householdId: householdId,
      week: week,
      board: board,
      childIds: childIds,
      aisle: aisle.shelves,
      aisleForModel: aisle.forModel,
    );
  }

  void addOwnIdea(LunchSlot slot, String text) =>
      ideas.addOwn(slot, text, rulesByChild);

  /// Ideas → the shop: every idea still for a child searched in turn, after
  /// the aisle's shelves still on the list, which are answered already.
  Future<void> searchStore() async {
    final active = ideas.active;
    if (active.isEmpty) return;
    final place = _place ??= await _places.resolve(householdId);
    final kept = {for (final idea in active) idea.id};
    _go(PlanWeekStep.store);
    await store.start(
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
  }

  Future<void> retrySearch(String ideaId) async {
    final place = _place;
    if (place == null) return;
    await store.retry(
      ideaId,
      near: place.coordinates,
      rulesByChild: rulesByChild,
    );
  }

  /// The shop → the week, read against [budget]: the household's weekly
  /// lunch budget as this phone last heard it.
  Future<void> buildWeek({Money? budget}) async {
    final board = _latestBoard;
    if (board == null || !store.hasKept || !store.isSettled) return;
    _go(PlanWeekStep.week);
    await shop.build(
      householdId: householdId,
      week: week,
      board: board,
      childIds: childIds,
      searches: store.searches,
      budget: budget,
    );
  }

  /// The week → done, once it is written.
  Future<void> use() async {
    final board = _latestBoard;
    if (board == null) return;
    if (await shop.use(board)) {
      _go(PlanWeekStep.done);
      _changed();
    }
  }

  /// One step back, keeping what the earlier step held.
  void back() {
    final previous = switch (_step) {
      PlanWeekStep.brief || PlanWeekStep.ideas => PlanWeekStep.brief,
      PlanWeekStep.store => PlanWeekStep.ideas,
      PlanWeekStep.week || PlanWeekStep.done => PlanWeekStep.store,
    };
    if (previous == PlanWeekStep.brief) {
      aisle.clear();
      ideas.clear();
    }
    if (previous.index < PlanWeekStep.store.index) store.clear();
    if (previous.index < PlanWeekStep.week.index) shop.clear();
    _go(previous);
    _changed();
  }

  void startOver() {
    aisle.clear();
    ideas.clear();
    store.clear();
    shop.clear();
    _go(PlanWeekStep.brief);
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

  void _go(PlanWeekStep step) => _step = step;

  /// Where the shop is searched. Unawaited from the constructor, so it
  /// keeps its own failure: a place that cannot be found is the resolver's
  /// own fallback city, which the brief names and the parent can change.
  Future<void> _resolvePlace() async {
    final place = await _placeOrFallback();
    _place ??= place;
    _changed();
  }

  Future<CheckersPlace> _placeOrFallback() async {
    try {
      return await _places.resolve(householdId);
    } on AppFailure {
      return const CheckersPlace.area(CheckersArea.fallback);
    }
  }

  void _changed() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    aisle.clear();
    ideas.clear();
    store.clear();
    shop.clear();
    super.dispose();
  }
}
