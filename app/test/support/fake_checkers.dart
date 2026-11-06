import 'dart:async';

import 'package:nestprep/features/add_to_checkers/data/checkers_area_preference.dart';
import 'package:nestprep/features/add_to_checkers/data/checkers_directory.dart';
import 'package:nestprep/features/add_to_checkers/data/match_as_you_type_preference.dart';
import 'package:nestprep/features/add_to_checkers/data/product_match_ranker.dart';
import 'package:nestprep/features/add_to_checkers/data/retailer_catalogue.dart';
import 'package:nestprep/features/add_to_checkers/data/retailer_catalogues.dart';
import 'package:nestprep/features/add_to_checkers/data/retailer_preference.dart';
import 'package:nestprep/features/add_to_checkers/model/cart_push_result.dart';
import 'package:nestprep/features/add_to_checkers/model/checkers_area.dart';
import 'package:nestprep/features/add_to_checkers/model/checkers_link_status.dart';
import 'package:nestprep/features/add_to_checkers/model/retailer_product.dart';
import 'package:nestprep/features/add_to_checkers/model/retailer_shelf.dart';
import 'package:nestprep/features/groceries/model/product_match.dart';
import 'package:nestprep/features/live_location/data/location_source.dart';
import 'package:nestprep/features/live_location/model/coordinates.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:nestprep/shared/money/money.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'fake_live_location.dart';

/// A Checkers product for a test, priced in cents.
RetailerProduct checkersProduct(
  String name, {
  String id = '5d3af63bf434cf8420737dd6',
  int cents = 3799,
  String unitOfMeasure = 'EA',
  String? brand = 'Clover',
  bool isOnPromotion = false,
  bool isInStock = true,
  int? oldCents,
}) => RetailerProduct(
  retailer: ProductRetailer.checkers,
  id: id,
  storeId: '62dabd7f832d656087c747d8',
  articleCode: '10136729$unitOfMeasure',
  unitOfMeasure: unitOfMeasure,
  isSoldByWeight: unitOfMeasure == 'KG',
  name: name,
  brand: brand,
  price: Money(cents),
  oldPrice: oldCents == null ? null : Money(oldCents),
  isOnPromotion: isOnPromotion,
  isInStock: isInStock,
);

/// The catalogue, answered by the test. A search waits on [gate] when one is
/// set, so a test can see the loading state before letting it finish.
final class FakeCheckersCatalogue implements RetailerCatalogue {
  List<RetailerProduct> products = const [];
  AppFailure? failWith;
  Completer<void>? gate;
  final searches = <({String query, Coordinates near})>[];

  @override
  Future<List<RetailerProduct>> search({
    required String query,
    required Coordinates near,
    int limit = RetailerCatalogue.defaultLimit,
  }) async {
    searches.add((query: query, near: near));
    await gate?.future;
    final failure = failWith;
    if (failure != null) throw failure;
    return products.take(limit).toList();
  }

  @override
  Future<List<RetailerProduct>> shelf({
    required RetailerShelf shelf,
    required Coordinates near,
    int limit = RetailerCatalogue.defaultLimit,
  }) async => const [];
}

final class FakeCheckersAreaPreference implements CheckersAreaPreference {
  final chosen = <String, CheckersArea>{};

  @override
  Future<CheckersArea?> read(String householdId) async => chosen[householdId];

  @override
  Future<void> write(String householdId, CheckersArea area) async =>
      chosen[householdId] = area;
}

final class FakeRetailerPreference
    implements RetailerPreference, MatchAsYouTypePreference {
  final chosen = <String, ProductRetailer>{};

  @override
  Future<ProductRetailer?> read(String householdId) async =>
      chosen[householdId];

  @override
  Future<void> write(String householdId, ProductRetailer retailer) async =>
      chosen[householdId] = retailer;

  final matchAsYouType = <String, bool>{};

  @override
  Future<bool?> readMatchAsYouType(String householdId) async =>
      matchAsYouType[householdId];

  @override
  Future<void> writeMatchAsYouType(
    String householdId, {
    required bool isOn,
  }) async => matchAsYouType[householdId] = isOn;
}

/// The five callables, answered by the test.
final class FakeCheckersDirectory implements CheckersDirectory {
  CheckersLinkStatus status = const CheckersLinkStatus.unlinked();
  CartPushResult? pushResult;

  /// Failures handed out, first in first out, before any answer.
  final pushFailures = <AppFailure>[];
  AppFailure? requestFailure;
  AppFailure? verifyFailure;
  AppFailure? statusFailure;
  Completer<void>? pushGate;

  final otpRequests = <String>[];
  final codes = <String>[];
  final pushes =
      <
        ({
          String householdId,
          List<String> itemIds,
          Map<String, int> quantities,
        })
      >[];
  var unlinks = 0;

  @override
  Future<CheckersLinkStatus> linkStatus() async {
    final failure = statusFailure;
    if (failure != null) throw failure;
    return status;
  }

  @override
  Future<String> requestOtp(String mobile) async {
    otpRequests.add(mobile);
    final failure = requestFailure;
    if (failure != null) throw failure;
    return '+27 82 *** 4567';
  }

  @override
  Future<CheckersLinkStatus> verifyOtp(String code) async {
    codes.add(code);
    final failure = verifyFailure;
    if (failure != null) throw failure;
    return status = CheckersLinkStatus(
      isLinked: true,
      expiresAt: DateTime.utc(2099),
      mobileMasked: '+27 82 *** 4567',
    );
  }

  @override
  Future<CartPushResult> pushToCart({
    required String householdId,
    required List<String> itemIds,
    Map<String, int> quantities = const {},
  }) async {
    pushes.add((
      householdId: householdId,
      itemIds: itemIds,
      quantities: quantities,
    ));
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

  @override
  Future<void> unlink() async {
    unlinks += 1;
    status = const CheckersLinkStatus.unlinked();
  }
}

/// Jev's scores, scripted: [fits] by product id, or [failure] thrown.
final class FakeProductMatchRanker implements ProductMatchRanker {
  Map<String, double> fits = const {};
  AppFailure? failure;
  final asked = <({String item, List<String> productIds})>[];

  @override
  Future<Map<String, double>> rank({
    required String householdId,
    required String item,
    required List<RetailerProduct> products,
  }) async {
    asked.add((item: item, productIds: [for (final p in products) p.id]));
    final failing = failure;
    if (failing != null) throw failing;
    return fits;
  }
}

/// What the app-wide graph registers for Checkers, faked, for a test that
/// builds the grocery route.
List<SingleChildWidget> fakeCheckersProviders({
  FakeCheckersCatalogue? catalogue,
  FakeCheckersDirectory? directory,
  FakeProductMatchRanker? ranker,
}) => [
  Provider<RetailerCatalogues>.value(
    value: RetailerCatalogues({
      ProductRetailer.checkers: catalogue ?? FakeCheckersCatalogue(),
    }),
  ),
  Provider<CheckersAreaPreference>.value(value: FakeCheckersAreaPreference()),
  Provider<RetailerPreference>.value(value: FakeRetailerPreference()),
  Provider<MatchAsYouTypePreference>.value(value: FakeRetailerPreference()),
  Provider<CheckersDirectory>.value(
    value: directory ?? FakeCheckersDirectory(),
  ),
  Provider<ProductMatchRanker>.value(value: ranker ?? FakeProductMatchRanker()),
  Provider<LocationSource>.value(value: FakeLocationSource()),
];
