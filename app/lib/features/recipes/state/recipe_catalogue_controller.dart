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
  }) : _repository = recipeRepository,
       _clock = householdClock {
    _subscribe();
  }

  final RecipeRepository _repository;
  final HouseholdClock _clock;

  StreamSubscription<List<Recipe>>? _subscription;
  AsyncState<RecipeCatalogue> _catalogue = const AsyncLoading();
  RecipeFilter _filter = const RecipeFilter();
  RecipeDiscovery? _discovery;

  AsyncState<RecipeCatalogue> get catalogue => _catalogue;
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
    _catalogue = const AsyncLoading();
    _discovery = null;
    notifyListeners();
    _subscribe();
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
      _catalogue = AsyncData(RecipeCatalogue(recipes));
      _derive();
      notifyListeners();
    }, onError: _onError);
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
    _catalogue = AsyncFailure(
      error is AppFailure ? error : UnknownFailure(error),
    );
    _discovery = null;
    notifyListeners();
  }

  Future<void> _cancel() async => _subscription?.cancel();

  @override
  void dispose() {
    unawaited(_cancel());
    super.dispose();
  }
}
