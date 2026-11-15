import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nestprep/app/basket_compare_route.dart';
import 'package:nestprep/app/basket_compare_routes.dart';
import 'package:nestprep/app/checkers_link_route.dart';
import 'package:nestprep/app/checkers_link_routes.dart';
import 'package:nestprep/app/pnp_link_route.dart';
import 'package:nestprep/app/pnp_link_routes.dart';
import 'package:nestprep/app/woolworths_link_route.dart';
import 'package:nestprep/app/woolworths_link_routes.dart';
import 'package:nestprep/features/add_to_checkers/data/checkers_directory.dart';
import 'package:nestprep/features/add_to_checkers/ui/checkers_link_screen.dart';
import 'package:nestprep/features/add_to_pnp/ui/pnp_link_screen.dart';
import 'package:nestprep/features/add_to_woolworths/ui/woolworths_link_screen.dart';
import 'package:nestprep/features/basket_compare/ui/basket_compare_screen.dart';
import 'package:nestprep/features/subscriptions/model/premium_feature.dart';
import 'package:nestprep/features/subscriptions/ui/premium_area.dart';
import 'package:nestprep/shared/copy/basket_compare_copy.dart';
import 'package:nestprep/shared/copy/checkers_copy.dart';
import 'package:nestprep/shared/copy/pnp_copy.dart';
import 'package:nestprep/shared/copy/subscription_copy.dart';
import 'package:nestprep/shared/copy/woolworths_copy.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../../../support/fake_checkers.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/premium_entitlement.dart';
import '../../../support/pump_screen.dart';

/// The shops are Premium (subscriptions ADR-0008): linking one and comparing
/// them show their place locked to a household without Premium, and nothing
/// behind it starts.
void main() {
  const id = Fixtures.householdId;

  Future<void> open(
    WidgetTester tester,
    String location, {
    List<SingleChildWidget> providers = const [],
  }) async {
    final router = GoRouter(
      initialLocation: location,
      routes: [
        checkersLinkRoute(),
        pnpLinkRoute(),
        woolworthsLinkRoute(),
        basketCompareRoute(),
      ],
    );
    addTearDown(router.dispose);
    await pumpRouter(tester, router: router, providers: providers);
    await tester.pumpAndSettle();
  }

  final places = {
    CheckersCopy.linkTitle: CheckersLinkRoute.pathFor(id),
    '${CheckersCopy.linkTitle}, from a cart push': CheckersLinkRoute.pathFor(
      id,
      returnWhenLinked: true,
    ),
    PnpCopy.linkTitle: PnpLinkRoute.pathFor(id),
    WoolworthsCopy.linkTitle: WoolworthsLinkRoute.pathFor(id),
    BasketCompareCopy.title: BasketCompareRoute.pathFor(id),
  };

  for (final MapEntry(key: place, value: location) in places.entries) {
    testWidgets('$place is locked without Premium', (tester) async {
      await open(tester, location);

      expect(tester.takeException(), isNull);
      expect(find.byType(PremiumLockedView), findsOneWidget);
      expect(
        find.text(SubscriptionCopy.headline(PremiumFeature.shops)),
        findsOneWidget,
      );
      for (final screen in [
        CheckersLinkScreen,
        PnpLinkScreen,
        WoolworthsLinkScreen,
        BasketCompareScreen,
      ]) {
        expect(find.byType(screen), findsNothing);
      }
    });
  }

  testWidgets('a Premium household opens the link screen', (tester) async {
    await open(
      tester,
      CheckersLinkRoute.pathFor(id),
      providers: [
        Provider<CheckersDirectory>.value(value: FakeCheckersDirectory()),
        premiumEntitlementProvider(),
      ],
    );

    expect(find.byType(PremiumLockedView), findsNothing);
    expect(find.byType(CheckersLinkScreen), findsOneWidget);
  });
}
