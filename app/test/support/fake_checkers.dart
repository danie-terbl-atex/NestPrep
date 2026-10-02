import 'dart:async';

import 'package:nestprep/features/add_to_checkers/data/checkers_area_preference.dart';
import 'package:nestprep/features/add_to_checkers/data/checkers_catalogue.dart';
import 'package:nestprep/features/add_to_checkers/data/checkers_directory.dart';
import 'package:nestprep/features/add_to_checkers/data/retailer_preference.dart';
import 'package:nestprep/features/add_to_checkers/model/checkers_area.dart';
import 'package:nestprep/features/add_to_checkers/model/checkers_link_status.dart';
import 'package:nestprep/features/add_to_checkers/model/checkers_product.dart';
import 'package:nestprep/features/add_to_checkers/model/checkers_push_result.dart';
import 'package:nestprep/features/add_to_checkers/model/checkers_shelf.dart';
import 'package:nestprep/features/groceries/model/product_match.dart';
import 'package:nestprep/features/live_location/data/location_source.dart';
import 'package:nestprep/features/live_location/model/coordinates.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:nestprep/shared/money/money.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'fake_live_location.dart';

/// A Checkers product for a test, priced in cents.
CheckersProduct checkersProduct(
  String name, {
  String id = '5d3af63bf434cf8420737dd6',
  int cents = 3799,
  String unitOfMeasure = 'EA',
  String? brand = 'Clover',
  bool isOnPromotion = false,
  bool isInStock = true,
  int? oldCents,
}) => CheckersProduct(
  id: id,
  storeId: '62dabd7f832d656087c747d8',
  articleNumber: '10136729',
  unitOfMeasure: unitOfMeasure,
  name: name,
  brand: brand,
  price: Money(cents),
  oldPrice: oldCents == null ? null : Money(oldCents),
  isOnPromotion: isOnPromotion,
  isInStock: isInStock,
);

/// The catalogue, answered by the test. A search waits on [gate] when one is
/// set, so a test can see the loading state before letting it finish.
final class FakeCheckersCatalogue implements CheckersCatalogue {
  List<CheckersProduct> products = const [];
  AppFailure? failWith;
  Completer<void>? gate;
  final searches = <({String query, Coordinates near})>[];

  @override
  Future<List<CheckersProduct>> search({
    required String query,
    required Coordinates near,
    int limit = CheckersCatalogue.defaultLimit,
  }) async {
    searches.add((query: query, near: near));
    await gate?.future;
    final failure = failWith;
    if (failure != null) throw failure;
    return products.take(limit).toList();
  }

  @override
  Future<List<CheckersProduct>> shelf({
    required CheckersShelf shelf,
    required Coordinates near,
    int limit = CheckersCatalogue.defaultLimit,
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

final class FakeRetailerPreference implements RetailerPreference {
  final chosen = <String, ProductRetailer>{};

  @override
  Future<ProductRetailer?> read(String householdId) async =>
      chosen[householdId];

  @override
  Future<void> write(String householdId, ProductRetailer retailer) async =>
      chosen[householdId] = retailer;
}

/// The five callables, answered by the test.
final class FakeCheckersDirectory implements CheckersDirectory {
  CheckersLinkStatus status = const CheckersLinkStatus.unlinked();
  CheckersPushResult? pushResult;

  /// Failures handed out, first in first out, before any answer.
  final pushFailures = <AppFailure>[];
  AppFailure? requestFailure;
  AppFailure? verifyFailure;
  AppFailure? statusFailure;
  Completer<void>? pushGate;

  final otpRequests = <String>[];
  final codes = <String>[];
  final pushes = <({String householdId, List<String> itemIds})>[];
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
  Future<CheckersPushResult> pushToCart({
    required String householdId,
    required List<String> itemIds,
  }) async {
    pushes.add((householdId: householdId, itemIds: itemIds));
    await pushGate?.future;
    if (pushFailures.isNotEmpty) throw pushFailures.removeAt(0);
    return pushResult ??
        const CheckersPushResult(
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

/// What the app-wide graph registers for Checkers, faked, for a test that
/// builds the grocery route.
List<SingleChildWidget> fakeCheckersProviders({
  FakeCheckersCatalogue? catalogue,
  FakeCheckersDirectory? directory,
}) => [
  Provider<CheckersCatalogue>.value(
    value: catalogue ?? FakeCheckersCatalogue(),
  ),
  Provider<CheckersAreaPreference>.value(value: FakeCheckersAreaPreference()),
  Provider<RetailerPreference>.value(value: FakeRetailerPreference()),
  Provider<CheckersDirectory>.value(
    value: directory ?? FakeCheckersDirectory(),
  ),
  Provider<LocationSource>.value(value: FakeLocationSource()),
];
