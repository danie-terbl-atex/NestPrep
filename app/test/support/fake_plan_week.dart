import 'dart:async';

import 'package:nestprep/features/add_to_checkers/data/cart_pusher.dart';
import 'package:nestprep/features/add_to_checkers/data/lunch_shop_preference.dart';
import 'package:nestprep/features/add_to_checkers/data/retailer_catalogue.dart';
import 'package:nestprep/features/add_to_checkers/data/retailer_catalogues.dart';
import 'package:nestprep/features/add_to_checkers/data/retailer_preference.dart';
import 'package:nestprep/features/add_to_checkers/model/cart_push_result.dart';
import 'package:nestprep/features/add_to_checkers/model/retailer_product.dart';
import 'package:nestprep/features/add_to_checkers/model/retailer_shelf.dart';
import 'package:nestprep/features/add_to_checkers/state/shop_carts.dart';
import 'package:nestprep/features/groceries/model/product_match.dart';
import 'package:nestprep/features/live_location/model/coordinates.dart';
import 'package:nestprep/features/lunch_box/model/lunch_variety.dart';
import 'package:nestprep/features/lunch_box/model/lunch_week.dart';
import 'package:nestprep/features/plan_week/data/lunch_aisle_source.dart';
import 'package:nestprep/features/plan_week/data/lunch_idea_drafter.dart';
import 'package:nestprep/features/plan_week/data/lunch_recipe_saver.dart';
import 'package:nestprep/features/plan_week/data/lunch_week_builder.dart';
import 'package:nestprep/features/plan_week/data/packing_choice_store.dart';
import 'package:nestprep/features/plan_week/model/aisle_shelf.dart';
import 'package:nestprep/features/plan_week/model/idea_search.dart';
import 'package:nestprep/features/plan_week/model/lunch_ideas_reply.dart';
import 'package:nestprep/features/plan_week/model/lunch_week_reply.dart';
import 'package:nestprep/features/plan_week/model/packing_preference.dart';
import 'package:nestprep/features/plan_week/state/lunch_shop_choice.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:nestprep/shared/money/money.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'fake_checkers.dart';
import 'household_fixtures.dart';

/// `draftLunchIdeas`, answered by the test: [reply], or [failWith].
final class FakeLunchIdeaDrafter implements LunchIdeaDrafter {
  LunchIdeasReply? reply;
  AppFailure? failWith;

  /// When set, an answer waits for it — so a test sees the step working.
  Completer<void>? gate;
  final asked = <Set<String>>[];
  final aisles = <List<AisleShelfNames>>[];
  final packed = <PackingChoice>[];

  @override
  Future<LunchIdeasReply> draft({
    required String householdId,
    required LunchWeek week,
    required Set<String> childIds,
    required PackingChoice packing,
    List<AisleShelfNames> aisle = const [],
  }) async {
    asked.add(childIds);
    aisles.add(aisle);
    packed.add(packing);
    await gate?.future;
    final failure = failWith;
    if (failure != null) throw failure;
    return reply ??
        LunchIdeasReply(ideas: const [], budgetCents: null, callsLeft: null);
  }
}

/// `buildLunchWeek`, answered by the test: [reply], or [failWith].
final class FakeLunchWeekBuilder implements LunchWeekBuilder {
  LunchWeekReply? reply;
  AppFailure? failWith;

  /// When set, an answer waits for it — so a test sees the week being built.
  Completer<void>? gate;
  final sent = <List<IdeaSearch>>[];
  final packed = <PackingChoice>[];
  final varieties = <LunchVariety>[];

  @override
  Future<LunchWeekReply> build({
    required String householdId,
    required LunchWeek week,
    required Set<String> childIds,
    required List<IdeaSearch> searches,
    required PackingChoice packing,
    required LunchVariety variety,
  }) async {
    sent.add(searches);
    packed.add(packing);
    varieties.add(variety);
    await gate?.future;
    final failure = failWith;
    if (failure != null) throw failure;
    return reply ??
        LunchWeekReply(
          lunches: const [],
          boxesPerPack: const {},
          budgetCents: null,
          dropped: 0,
          callsLeft: null,
        );
  }
}

/// `saveLunchRecipes`, answered by the test: each dish saved as `ai-<n>`
/// with its own codes and the labels' — or [failWith]. Every call recorded.
final class FakeLunchRecipeSaver implements LunchRecipeSaver {
  AppFailure? failWith;
  final saved = <List<DishToSave>>[];

  @override
  Future<List<SavedLunchRecipe>> save({
    required String householdId,
    required List<DishToSave> dishes,
  }) async {
    saved.add(dishes);
    final failure = failWith;
    if (failure != null) throw failure;
    return [
      for (final (index, (:draft, :alsoContains)) in dishes.indexed)
        SavedLunchRecipe(
          id: 'ai-${index + 1}',
          allergens: {...draft.allergens, ...alsoContains},
        ),
    ];
  }
}

/// The shop, answering each search by its words and each shelf by its id;
/// [failFor] fails a search, [failShelf] a shelf.
final class FakeShopCatalogue implements RetailerCatalogue {
  final byQuery = <String, List<RetailerProduct>>{};
  final byShelf = <RetailerShelf, List<RetailerProduct>>{};
  final failFor = <String, AppFailure>{};
  final failShelf = <RetailerShelf, AppFailure>{};
  final queries = <String>[];
  final shelves = <RetailerShelf>[];

  /// How many products each shelf read asked for, in order.
  final shelfLimits = <int>[];

  /// When set, a search waits for it — so a test sees the shop working.
  Completer<void>? gate;

  @override
  Future<List<RetailerProduct>> search({
    required String query,
    required Coordinates near,
    int limit = RetailerCatalogue.defaultLimit,
  }) async {
    queries.add(query);
    await gate?.future;
    final failure = failFor[query];
    if (failure != null) throw failure;
    return (byQuery[query] ?? const []).take(limit).toList();
  }

  @override
  Future<List<RetailerProduct>> shelf({
    required RetailerShelf shelf,
    required Coordinates near,
    int limit = RetailerCatalogue.defaultLimit,
  }) async {
    shelves.add(shelf);
    shelfLimits.add(limit);
    final failure = failShelf[shelf];
    if (failure != null) throw failure;
    return (byShelf[shelf] ?? const []).take(limit).toList();
  }
}

/// The shelves to read, decided by the test: none unless it says so, so a
/// test about something else is not walking the aisle.
final class FakeLunchAisleSource implements LunchAisleSource {
  List<AisleShelf> answer = const [];

  /// The shops asked for, in order.
  final askedFor = <ProductRetailer>[];

  /// When set, the shelf list waits for it — so a test sees the aisle read.
  Completer<void>? gate;

  @override
  Future<List<AisleShelf>> shelves(ProductRetailer shop) async {
    askedFor.add(shop);
    await gate?.future;
    return answer;
  }
}

/// The packing choices this phone remembers, per household; [failRead]
/// answers as an unreadable store does.
final class FakePackingChoiceStore implements PackingChoiceStore {
  final kept = <String, PackingChoice>{};
  var failRead = false;

  @override
  Future<PackingChoice?> read(String householdId) async =>
      failRead ? null : kept[householdId];

  @override
  Future<void> write(String householdId, PackingChoice choice) async =>
      kept[householdId] = choice;
}

/// The shop chosen for lunches on this phone, kept in memory.
final class FakeLunchShopPreference implements LunchShopPreference {
  final kept = <String, ProductRetailer>{};

  @override
  Future<ProductRetailer?> read(String householdId) async => kept[householdId];

  @override
  Future<void> write(String householdId, ProductRetailer retailer) async =>
      kept[householdId] = retailer;
}

/// Every shop's catalogue for a *Plan my week* test: [checkers], and
/// [pickNPay] and [woolworths] — which, unless given, answer nothing.
RetailerCatalogues planWeekCatalogues(
  RetailerCatalogue checkers, {
  RetailerCatalogue? pickNPay,
  RetailerCatalogue? woolworths,
}) => RetailerCatalogues({
  ProductRetailer.checkers: checkers,
  ProductRetailer.pickNPay: pickNPay ?? FakeShopCatalogue(),
  ProductRetailer.woolworths: woolworths ?? FakeShopCatalogue(),
});

/// The shops switched on in a *Plan my week* test: Checkers alone unless it
/// says otherwise.
List<ProductRetailer> Function() planWeekShopsOn([
  List<ProductRetailer> shops = const [ProductRetailer.checkers],
]) =>
    () => shops;

/// The lunch shop choice for [householdId], kept in [preference], led by
/// the family's shop in [family].
LunchShopChoice planWeekShopChoice(
  String householdId, {
  LunchShopPreference? preference,
  RetailerPreference? family,
}) => LunchShopChoice(
  preference: preference ?? FakeLunchShopPreference(),
  familyPreference: family ?? FakeRetailerPreference(),
  householdId: householdId,
);

/// A shop's cart push answered by the test: [pushResult], or each of
/// [pushFailures] in turn; every push recorded with its packs.
final class FakeCartPusher implements CartPusher {
  CartPushResult? pushResult;
  final pushFailures = <AppFailure>[];
  Completer<void>? pushGate;
  final pushes = <({List<String> itemIds, Map<String, int> quantities})>[];

  @override
  Future<CartPushResult> pushToCart({
    required String householdId,
    required List<String> itemIds,
    Map<String, int> quantities = const {},
  }) async {
    pushes.add((itemIds: itemIds, quantities: quantities));
    await pushGate?.future;
    if (pushFailures.isNotEmpty) throw pushFailures.removeAt(0);
    return pushResult ??
        const CartPushResult(
          added: [],
          skipped: [],
          cartItemCount: 0,
          cartTotal: Money.zero(),
        );
  }
}

/// Every shop's cart push for a pumped *Plan my week*, answering nothing.
SingleChildWidget planWeekCartsProvider() => Provider<ShopCarts>(
  create: (_) => ShopCarts.over({
    for (final shop in ProductRetailer.values) shop: FakeCartPusher(),
  }, householdId: Fixtures.householdId),
  dispose: (_, carts) => carts.dispose(),
);
