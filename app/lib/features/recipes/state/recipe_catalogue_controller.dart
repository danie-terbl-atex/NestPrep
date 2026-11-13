import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/async/async_state.dart';
import '../../../shared/failure/app_failure.dart';
import '../../../shared/time/household_clock.dart';
import '../data/recipe_repository.dart';
import '../model/recipe.dart';
import '../model/recipe_catalogue.dart';
import '../model/recipe_discovery.dart';
import '../model/recipe_facet.dart';
import '../model/recipe_filter.dart';
import '../model/recipe_meal_filter.dart';

/// The Meals tab's recipes (recipes ADR-0003): the published catalogue as its
/// listener last delivered it, what somebody has asked of it, and what that
/// shows — derived once per change, never in a build (`FE-12`).
///
/// It lives on the Meals tab's shell, so the recipe page and the meal plan's
/// recipe-linked meals read the same one listener rather than a second
/// (foundation ADR-0006). The filter is this tab's own UI state; it holds
/// nothing the listener does not also hold (`FE-07`).
final class RecipeCatalogueController extends ChangeNotifier {
  RecipeCatalogueController({
    required RecipeRepository recipeRepository,
    required HouseholdClock householdClock,
    this.ownRecipesOf,
  }) : _repository = recipeRepository,
       _clock = householdClock {
    _subscribe();
    _subscribeToOwn();
  }

  final RecipeRepository _repository;
  final HouseholdClock _clock;

  /// The household whose own recipes join the catalogue; null for somebody the
  /// rules would not let read them.
  final String? ownRecipesOf;

  StreamSubscription<List<Recipe>>? _subscription;
  StreamSubscription<List<Recipe>>? _ownSubscription;
  List<Recipe>? _published;
  List<Recipe>? _own;
  AppFailure? _ownFailure;
  AsyncState<RecipeCatalogue> _catalogue = const AsyncLoading();
  RecipeFilter _filter = const RecipeFilter();
  RecipeDiscovery? _discovery;

  AsyncState<RecipeCatalogue> get catalogue => _catalogue;

  AppFailure? get ownFailure => _ownFailure;
  RecipeFilter get filter => _filter;

  /// What the recipes view shows, or null until the catalogue has arrived.
  RecipeDiscovery? get discovery => _discovery;

  /// One recipe by id, once the catalogue is in — for the recipe page and a
  /// planned meal's picture. Null while loading and for an id it does not
  /// hold.
  Recipe? recipe(String id) => switch (_catalogue) {
    AsyncData(:final value) => value.byId[id],
    _ => null,
  };

  void search(String query) => _refilter(_filter.withQuery(query));

  void selectMeal(RecipeMealFilter meal) => _refilter(_filter.withMeal(meal));

  void toggleFacet(RecipeFacet facet) => _refilter(_filter.toggling(facet));

  /// Back to the editorial page — the way out of "nothing matches".
  void clearFilter() => _refilter(const RecipeFilter());

  /// Listens again at once; the failed listener is let go alongside rather
  /// than first, so the retry never waits on it.
  Future<void> retry() async {
    final stale = _subscription?.cancel();
    final staleOwn = _ownSubscription?.cancel();
    _published = null;
    _own = null;
    _ownFailure = null;
    _catalogue = const AsyncLoading();
    _discovery = null;
    notifyListeners();
    _subscribe();
    _subscribeToOwn();
    await stale;
    await staleOwn;
  }

  Future<void> retryOwnRecipes() async {
    final stale = _ownSubscription?.cancel();
    _ownFailure = null;
    notifyListeners();
    _subscribeToOwn();
    await stale;
  }

  void _refilter(RecipeFilter filter) {
    if (filter == _filter) return;
    _filter = filter;
    _derive();
    notifyListeners();
  }

  void _subscribe() {
    _subscription = _repository.watchCatalogue().listen((recipes) {
      _published = recipes;
      _merge();
    }, onError: _onError);
  }

  void _subscribeToOwn() {
    final householdId = ownRecipesOf;
    if (householdId == null) return;
    _ownSubscription = _repository.watchOwnRecipes(householdId).listen((own) {
      _own = own;
      _ownFailure = null;
      _merge();
    }, onError: _onOwnError);
  }

  bool get _ownHasAnswered =>
      ownRecipesOf == null || _own != null || _ownFailure != null;

  // Holding here is what stops an own recipe's page flashing "gone" while only
  // the catalogue has arrived.
  void _merge() {
    final published = _published;
    if (published != null && _ownHasAnswered) {
      _catalogue = AsyncData(
        RecipeCatalogue.merged(published, _own ?? const []),
      );
      _derive();
    }
    notifyListeners();
  }

  void _onOwnError(Object error) {
    _ownFailure = error is AppFailure ? error : UnknownFailure(error);
    _merge();
  }

  void _derive() {
    _discovery = switch (_catalogue) {
      AsyncData(:final value) => RecipeDiscovery.of(
        value,
        filter: _filter,
        today: _clock.today,
      ),
      _ => null,
    };
  }

  void _onError(Object error) {
    _published = null;
    _catalogue = AsyncFailure(
      error is AppFailure ? error : UnknownFailure(error),
    );
    _discovery = null;
    notifyListeners();
  }

  Future<void> _cancel() async {
    await _subscription?.cancel();
    await _ownSubscription?.cancel();
  }

  @override
  void dispose() {
    unawaited(_cancel());
    super.dispose();
  }
}
