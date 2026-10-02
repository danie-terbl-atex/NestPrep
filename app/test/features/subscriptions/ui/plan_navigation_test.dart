import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nestprep/app/household_route.dart';
import 'package:nestprep/app/household_shell.dart';
import 'package:nestprep/app/subscription_routes.dart';
import 'package:nestprep/features/household/model/household_view.dart';
import 'package:nestprep/features/household/state/household_controller.dart';
import 'package:nestprep/features/household/ui/household_more_screen.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/copy/subscription_copy.dart';
import 'package:nestprep/shared/links/external_link_opener.dart';
import 'package:provider/provider.dart';

import '../../../support/fake_household.dart';
import '../../../support/fake_link_opener.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/pump_screen.dart';
import '../../../support/pump_subscriptions.dart';

/// Plan and billing is reached from More, by family, and
/// opens over it with a way back (`FE-17`, subscriptions ADR-0001) — a
/// capability with no way in is not done (the vault lesson).
void main() {
  Future<void> pump(WidgetTester tester, {required String viewerUid}) async {
    tester.view.physicalSize = const Size(420 * 3, 1600 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final premium = SubscriptionHarness();
    final households = FakeHouseholdRepository();
    final controller = HouseholdController(
      householdRepository: households,
      householdDirectory: FakeHouseholdDirectory(),
      householdId: Fixtures.householdId,
      viewerUid: viewerUid,
    );
    addTearDown(() async {
      controller.dispose();
      await households.close();
    });
    await pumpRouter(
      tester,
      router: GoRouter(
        initialLocation: HouseholdRoute.pathFor(
          Fixtures.householdId,
          HouseholdTab.more,
        ),
        routes: [
          GoRoute(
            path: '${HouseholdRoute.path}/${HouseholdTab.more.segment}',
            builder: (context, state) =>
                HouseholdMoreScreen(onSelectTab: (_) {}),
          ),
          subscriptionRoute(),
        ],
      ),
      view: Fixtures.view(viewerUid: viewerUid),
      providers: [
        ChangeNotifierProvider<HouseholdController>.value(value: controller),
        Provider<ExternalLinkOpener>.value(value: FakeLinkOpener()),
        ...premium.providers,
      ],
    );
    households.emitHousehold(Fixtures.household());
    households.emitMembers([Fixtures.sam, Fixtures.thandi, Fixtures.kid]);
    await tester.pumpAndSettle();
  }

  testWidgets('More is the way in, and back comes back', (tester) async {
    await pump(tester, viewerUid: Fixtures.samUid);
    expect(
      find.text(SubscriptionCopy.openFromHouseholdBody(isPremium: false)),
      findsOneWidget,
    );
    await tester.ensureVisible(find.text(SubscriptionCopy.openFromHousehold));
    await tester.pumpAndSettle();
    await tester.tap(find.text(SubscriptionCopy.openFromHousehold));
    await tester.pumpAndSettle();

    expect(find.text(SubscriptionCopy.planTitle), findsOneWidget);
    expect(find.text(SubscriptionCopy.freeSummary), findsOneWidget);
    await tester.tap(find.byIcon(LucideIcons.arrowLeft));
    await tester.pumpAndSettle();
    expect(find.text(MoreCopy.subtitle), findsOneWidget);
  });

  testWidgets('a helper, who does not buy, is not offered the way in', (
    tester,
  ) async {
    await pump(tester, viewerUid: Fixtures.thandiUid);
    expect(find.text(SubscriptionCopy.openFromHousehold), findsNothing);
    // The view is the helper's own, which is what the link is decided on.
    expect(
      tester
          .element(find.byType(HouseholdMoreScreen))
          .read<HouseholdView>()
          .permissions
          .isFamily,
      isFalse,
    );
  });
}
