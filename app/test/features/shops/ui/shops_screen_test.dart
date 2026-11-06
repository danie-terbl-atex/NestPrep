import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nestprep/app/checkers_link_route.dart';
import 'package:nestprep/app/pnp_link_route.dart';
import 'package:nestprep/app/shops_route.dart';
import 'package:nestprep/app/shops_routes.dart';
import 'package:nestprep/app/woolworths_link_route.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/add_to_checkers/data/checkers_directory.dart';
import 'package:nestprep/features/add_to_checkers/data/match_as_you_type_preference.dart';
import 'package:nestprep/features/add_to_checkers/data/retailer_preference.dart';
import 'package:nestprep/features/add_to_checkers/model/checkers_link_status.dart';
import 'package:nestprep/features/add_to_pnp/data/pnp_directory.dart';
import 'package:nestprep/features/add_to_pnp/model/pnp_link_status.dart';
import 'package:nestprep/features/add_to_woolworths/data/woolworths_directory.dart';
import 'package:nestprep/features/add_to_woolworths/model/woolworths_link_status.dart';
import 'package:nestprep/features/groceries/model/product_match.dart';
import 'package:nestprep/features/household/model/access_grant.dart';
import 'package:nestprep/features/household/model/access_level.dart';
import 'package:nestprep/features/household/model/household_area.dart';
import 'package:nestprep/features/household/model/household_view.dart';
import 'package:nestprep/features/shops/state/shops_controller.dart';
import 'package:nestprep/features/shops/ui/shops_screen.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/copy/checkers_copy.dart';
import 'package:nestprep/shared/copy/shops_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:nestprep/shared/flags/feature_flags.dart';
import 'package:nestprep/shared/flags/feature_flags_controller.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../../../support/fake_checkers.dart';
import '../../../support/fake_feature_flag_source.dart';
import '../../../support/fake_pnp.dart';
import '../../../support/fake_woolworths.dart';
import '../../../support/held_pnp_directory.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/pump_screen.dart';

void main() {
  late FakeCheckersDirectory checkers;
  late FakePnpDirectory pnp;
  late FakeWoolworthsDirectory woolworths;
  late FakeRetailerPreference preference;

  setUp(() {
    checkers = FakeCheckersDirectory();
    pnp = FakePnpDirectory();
    woolworths = FakeWoolworthsDirectory();
    preference = FakeRetailerPreference();
  });

  Future<void> pumpShops(
    WidgetTester tester, {
    HouseholdView? view,
    PnpDirectory? pnpDirectory,
    List<SingleChildWidget> extra = const [],
    bool opensFromHome = false,
    Brightness brightness = Brightness.light,
    double scale = 1,
  }) async {
    GoRoute placeholder(String path) => GoRoute(
      path: path,
      builder: (_, state) => Text('page ${state.uri.path}'),
    );
    await pumpRouter(
      tester,
      router: GoRouter(
        initialLocation: opensFromHome
            ? '/'
            : ShopsRoute.pathFor(Fixtures.householdId),
        routes: [
          GoRoute(path: '/', builder: (_, _) => const Text('home')),
          shopsRoute(),
          placeholder(CheckersLinkRoute.path),
          placeholder(PnpLinkRoute.path),
          placeholder(WoolworthsLinkRoute.path),
        ],
      ),
      providers: [
        Provider<CheckersDirectory>.value(value: checkers),
        Provider<PnpDirectory>.value(value: pnpDirectory ?? pnp),
        Provider<WoolworthsDirectory>.value(value: woolworths),
        Provider<RetailerPreference>.value(value: preference),
        Provider<MatchAsYouTypePreference>.value(value: preference),
        ...extra,
      ],
      view: view,
      brightness: brightness,
      textScale: scale,
    );
    await tester.pumpAndSettle();
  }

  Finder linkRow(ProductRetailer shop) =>
      find.byKey(ValueKey('shops-link-${shop.code}'));

  Finder inLinkRow(ProductRetailer shop, Finder finder) =>
      find.descendant(of: linkRow(shop), matching: finder);

  Future<void> bringIntoView(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('every shop switched on, linked or not, and what linking does', (
    tester,
  ) async {
    checkers.status = CheckersLinkStatus(
      isLinked: true,
      expiresAt: DateTime.now().add(const Duration(minutes: 30)),
      mobileMasked: '082***4567',
    );
    woolworths.status = WoolworthsLinkStatus(
      isLinked: true,
      linkedAt: DateTime.utc(2026, 11, 2),
      emailMasked: 'd***@a***.io',
    );
    await pumpShops(tester);

    for (final shop in ProductRetailer.values) {
      expect(find.byKey(ValueKey('shops-first-${shop.code}')), findsOneWidget);
    }
    expect(find.text(ShopsCopy.linkingNote), findsOneWidget);
    expect(find.text(ShopsCopy.signInNote), findsOneWidget);

    await bringIntoView(tester, linkRow(ProductRetailer.woolworths));
    expect(
      inLinkRow(
        ProductRetailer.checkers,
        find.text(ShopsCopy.linkedTo('082***4567')),
      ),
      findsOneWidget,
    );
    expect(
      inLinkRow(ProductRetailer.checkers, find.text(ShopsCopy.manage)),
      findsOneWidget,
    );
    expect(
      inLinkRow(ProductRetailer.pickNPay, find.text(ShopsCopy.notLinked)),
      findsOneWidget,
    );
    expect(
      inLinkRow(ProductRetailer.pickNPay, find.text(ShopsCopy.link)),
      findsOneWidget,
    );
    expect(
      inLinkRow(
        ProductRetailer.woolworths,
        find.text(ShopsCopy.linkedTo('d***@a***.io')),
      ),
      findsOneWidget,
    );
  });

  testWidgets('a switched-off shop is not shown at all', (tester) async {
    await pumpShops(
      tester,
      opensFromHome: true,
      extra: [
        ChangeNotifierProvider<FeatureFlagsController>(
          create: (_) => FeatureFlagsController(
            source: FixedFeatureFlagSource(
              FeatureFlags.fromFields(const {
                'addToWoolworths': false,
              }, defaultOn: true),
            ),
          ),
        ),
      ],
    );
    unawaited(
      GoRouter.of(tester.element(find.text('home')))
          .push<void>(ShopsRoute.pathFor(Fixtures.householdId)),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('shops-first-woolworths')), findsNothing);
    expect(linkRow(ProductRetailer.woolworths), findsNothing);
    expect(find.byKey(const ValueKey('shops-first-checkers')), findsOneWidget);
    expect(find.byKey(const ValueKey('shops-first-pickNPay')), findsOneWidget);
  });

  testWidgets('a shop that cannot be checked says so beside the others', (
    tester,
  ) async {
    pnp.statusFailure = const UnavailableFailure();
    await pumpShops(tester);
    await bringIntoView(tester, linkRow(ProductRetailer.woolworths));

    expect(
      inLinkRow(
        ProductRetailer.pickNPay,
        find.text(AppCopy.failure(const UnavailableFailure())),
      ),
      findsOneWidget,
    );
    expect(
      inLinkRow(ProductRetailer.checkers, find.text(ShopsCopy.notLinked)),
      findsOneWidget,
    );
    expect(
      inLinkRow(ProductRetailer.woolworths, find.text(ShopsCopy.notLinked)),
      findsOneWidget,
    );

    pnp.statusFailure = null;
    await tester.tap(
      inLinkRow(ProductRetailer.pickNPay, find.text(AppCopy.retry)),
    );
    await tester.pumpAndSettle();
    expect(
      inLinkRow(ProductRetailer.pickNPay, find.text(ShopsCopy.notLinked)),
      findsOneWidget,
    );
  });

  testWidgets('while a shop is being checked it says so', (tester) async {
    final held = HeldPnpDirectory();
    await pumpShops(tester, pnpDirectory: held);
    await bringIntoView(tester, linkRow(ProductRetailer.woolworths));
    expect(
      inLinkRow(ProductRetailer.pickNPay, find.text(ShopsCopy.checking)),
      findsOneWidget,
    );
    expect(
      inLinkRow(ProductRetailer.pickNPay, find.byType(NestButton)),
      findsNothing,
    );
    expect(
      inLinkRow(ProductRetailer.checkers, find.text(ShopsCopy.notLinked)),
      findsOneWidget,
    );

    held.answer.complete(
      PnpLinkStatus(isLinked: true, linkedAt: DateTime(2026)),
    );
    await tester.pumpAndSettle();
    expect(
      inLinkRow(ProductRetailer.pickNPay, find.text(ShopsCopy.linked)),
      findsOneWidget,
    );
  });

  testWidgets('starts at the shop chosen before, and choosing one keeps it', (
    tester,
  ) async {
    preference.chosen[Fixtures.householdId] = ProductRetailer.pickNPay;
    await pumpShops(tester);

    Finder tickIn(ProductRetailer shop) => find.descendant(
      of: find.byKey(ValueKey('shops-first-${shop.code}')),
      matching: find.byIcon(LucideIcons.check),
    );

    expect(tickIn(ProductRetailer.pickNPay), findsOneWidget);
    expect(tickIn(ProductRetailer.checkers), findsNothing);

    await tester.tap(find.byKey(const ValueKey('shops-first-woolworths')));
    await tester.pumpAndSettle();
    expect(preference.chosen[Fixtures.householdId], ProductRetailer.woolworths);
    expect(tickIn(ProductRetailer.woolworths), findsOneWidget);
    expect(tickIn(ProductRetailer.pickNPay), findsNothing);
  });

  testWidgets('Link opens that shop’s link screen, and back checks again', (
    tester,
  ) async {
    await pumpShops(tester);
    await bringIntoView(tester, linkRow(ProductRetailer.woolworths));
    await tester.tap(
      inLinkRow(ProductRetailer.woolworths, find.text(ShopsCopy.link)),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('page ${WoolworthsLinkRoute.pathFor(Fixtures.householdId)}'),
      findsOneWidget,
    );

    woolworths.status = WoolworthsLinkStatus(
      isLinked: true,
      linkedAt: DateTime.utc(2026, 11, 5),
      emailMasked: 'd***@a***.io',
    );
    GoRouter.of(tester.element(find.textContaining('page '))).pop();
    await tester.pumpAndSettle();
    await bringIntoView(tester, linkRow(ProductRetailer.woolworths));
    expect(
      inLinkRow(
        ProductRetailer.woolworths,
        find.text(ShopsCopy.linkedTo('d***@a***.io')),
      ),
      findsOneWidget,
    );
  });

  testWidgets('somebody who may only read the list is offered no shop', (
    tester,
  ) async {
    await pumpShops(
      tester,
      view: Fixtures.helperView(
        AccessGrant({HouseholdArea.groceries: AccessLevel.view}),
      ),
    );
    expect(find.text(ShopsCopy.notYoursTitle), findsOneWidget);
    expect(find.text(ShopsCopy.link), findsNothing);
    expect(
      tester.element(find.byType(ShopsScreen)).read<ShopsController>().shops,
      isEmpty,
    );
  });

  testWidgets('every shop switched off says so', (tester) async {
    await pumpShops(tester, extra: [featureFlagsProvider(defaultOn: false)]);
    expect(find.text(ShopsCopy.noneOnTitle), findsOneWidget);
    expect(
      find.text(CheckersCopy.retailerName(ProductRetailer.checkers)),
      findsNothing,
    );
  });

  for (final failing in [false, true]) {
    testWidgets('survives dark at 200% text on a 360-wide phone'
        '${failing ? ', with a shop that cannot be checked' : ''}', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360 * 3, 800 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      woolworths.status = WoolworthsLinkStatus(
        isLinked: true,
        linkedAt: DateTime.utc(2026, 11, 2),
        emailMasked: 'd***@a***.io',
      );
      if (failing) pnp.statusFailure = const UnavailableFailure();
      await pumpShops(tester, brightness: Brightness.dark, scale: 2);
      await bringIntoView(tester, linkRow(ProductRetailer.woolworths));
      expect(tester.takeException(), isNull);
    });
  }
}
