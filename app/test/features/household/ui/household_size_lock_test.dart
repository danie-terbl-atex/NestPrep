import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nestprep/app/assistants_route.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/assistants/ui/assistants_link.dart';
import 'package:nestprep/features/household/model/access_defaults.dart';
import 'package:nestprep/features/household/model/household_view.dart';
import 'package:nestprep/features/household/model/member.dart';
import 'package:nestprep/features/household/ui/household_size_lock.dart';
import 'package:nestprep/features/subscriptions/model/entitlement.dart';
import 'package:nestprep/features/subscriptions/model/entitlement_status.dart';
import 'package:nestprep/features/subscriptions/model/premium_feature.dart';
import 'package:nestprep/features/subscriptions/state/household_entitlement.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/copy/subscription_copy.dart';
import 'package:provider/provider.dart';

import '../../../support/fake_subscriptions.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/pump_screen.dart';
import '../../../support/pump_subscriptions.dart';

/// A free household holding more than four people is stopped everywhere but
/// where it can put that right (subscriptions ADR-0008).
void main() {
  const place = Text('the place itself');

  List<Member> people(int count) => [
    Fixtures.sam,
    Fixtures.thandi,
    for (var index = 2; index < count; index++)
      Fixtures.kid.copyWith(id: 'm-kid-$index', displayName: 'Kid $index'),
  ];

  Entitlement premium() => Entitlement(
    premiumUntil: DateTime.now().add(const Duration(days: 30)),
    status: EntitlementStatus.active,
    willRenew: true,
  );

  Future<SubscriptionHarness> pump(
    WidgetTester tester, {
    required HouseholdView view,
    Entitlement entitlement = Entitlement.free,
    bool isOpenHere = false,
    Brightness brightness = Brightness.light,
    double scale = 1,
  }) async {
    final harness = SubscriptionHarness(entitlement: entitlement);
    await pumpRouter(
      tester,
      router: GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) =>
                HouseholdSizeLock(isOpenHere: isOpenHere, child: place),
          ),
          GoRoute(
            path: '/households/:householdId/household',
            builder: (context, state) => const Text('the people screen'),
          ),
          GoRoute(
            path: AssistantsRoute.path,
            builder: (context, state) => const Text('the assistants screen'),
          ),
        ],
      ),
      providers: harness.providers,
      view: view,
      brightness: brightness,
      textScale: scale,
    );
    await tester.pumpAndSettle();
    return harness;
  }

  testWidgets('four people on the free plan carry on', (tester) async {
    await pump(tester, view: Fixtures.view(members: people(4)));
    expect(find.byWidget(place), findsOneWidget);
    expect(find.byType(HouseholdOverLimitScreen), findsNothing);
  });

  testWidgets('five on the free plan are stopped, told how many they are, '
      'and offered both ways on', (tester) async {
    await pump(tester, view: Fixtures.view(members: people(5)));

    expect(find.byWidget(place), findsNothing);
    expect(find.text(AccessCopy.overLimitTitle), findsOneWidget);
    expect(find.text(AccessCopy.overLimitBody(5)), findsOneWidget);
    expect(
      find.widgetWithText(NestButton, AccessCopy.overLimitManage),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(NestButton, SubscriptionCopy.seePremium),
      findsOneWidget,
    );
    expect(find.text(AccessCopy.overLimitAskParent), findsNothing);
  });

  testWidgets('five with Premium carry on', (tester) async {
    await pump(
      tester,
      view: Fixtures.view(members: people(5)),
      entitlement: premium(),
    );
    expect(find.byWidget(place), findsOneWidget);
  });

  testWidgets('a place that stays open is never replaced', (tester) async {
    await pump(
      tester,
      view: Fixtures.view(members: people(6)),
      isOpenHere: true,
    );
    expect(find.byWidget(place), findsOneWidget);
  });

  testWidgets('nothing is locked while the entitlement is still unknown, and '
      'the lock lifts by itself when Premium starts', (tester) async {
    final entitlements = FakeEntitlementRepository();
    addTearDown(entitlements.close);
    await pumpRouter(
      tester,
      router: GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) =>
                const HouseholdSizeLock(isOpenHere: false, child: place),
          ),
        ],
      ),
      providers: [
        ChangeNotifierProvider<HouseholdEntitlement>(
          create: (_) => HouseholdEntitlement(
            entitlementRepository: entitlements,
            householdId: Fixtures.householdId,
          ),
        ),
      ],
      view: Fixtures.view(members: people(5)),
    );
    await tester.pumpAndSettle();
    expect(find.byWidget(place), findsOneWidget);

    entitlements.emit(Entitlement.free);
    await tester.pumpAndSettle();
    expect(find.byType(HouseholdOverLimitScreen), findsOneWidget);

    entitlements.emit(premium());
    await tester.pumpAndSettle();
    expect(find.byWidget(place), findsOneWidget);
    expect(find.byType(HouseholdOverLimitScreen), findsNothing);
  });

  testWidgets('Manage household opens the people screen over it, so back '
      'comes back here', (tester) async {
    await pump(tester, view: Fixtures.view(members: people(5)));

    await tester.tap(find.text(AccessCopy.overLimitManage));
    await tester.pumpAndSettle();
    expect(find.text('the people screen'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text(AccessCopy.overLimitTitle), findsOneWidget);
  });

  testWidgets('See Premium opens the paywall on the household’s size', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(420 * 3, 1600 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final harness = await pump(tester, view: Fixtures.view(members: people(5)));

    await tester.tap(find.text(SubscriptionCopy.seePremium));
    await tester.pumpAndSettle();

    expect(
      find.text(SubscriptionCopy.headline(PremiumFeature.householdSize)),
      findsOneWidget,
    );
    expect(
      harness.paywallOpens.opened.single.trigger,
      PremiumFeature.householdSize,
    );
  });

  HouseholdView asAHelper() => HouseholdView(
    household: Fixtures.household().copyWith(
      access: {Fixtures.thandiUid: AccessDefaults.helper},
      profiles: {Fixtures.thandiUid: Fixtures.thandiMemberId},
    ),
    members: people(5),
    viewerUid: Fixtures.thandiUid,
  );

  testWidgets('a helper is told, asked to find a parent, and shown the way '
      'to the people screen, where leaving is — with nothing to buy', (
    tester,
  ) async {
    final harness = await pump(tester, view: asAHelper());

    expect(find.text(AccessCopy.overLimitBody(5)), findsOneWidget);
    expect(find.text(AccessCopy.overLimitAskParent), findsOneWidget);
    expect(find.text(AccessCopy.overLimitManage), findsNothing);
    expect(find.text(SubscriptionCopy.seePremium), findsNothing);
    expect(
      find.widgetWithText(NestButton, AccessCopy.overLimitSeeHousehold),
      findsOneWidget,
    );
    expect(find.byType(NestButton), findsOneWidget);

    await tester.tap(find.text(AccessCopy.overLimitSeeHousehold));
    await tester.pumpAndSettle();
    expect(find.text('the people screen'), findsOneWidget);
    expect(harness.paywallOpens.opened, isEmpty);
  });

  for (final (who, view) in [
    ('a parent', () => Fixtures.view(members: people(5))),
    ('a helper', asAHelper),
  ]) {
    testWidgets('$who can still reach Connected assistants, to disconnect', (
      tester,
    ) async {
      await pump(tester, view: view());

      await tester.scrollUntilVisible(find.byType(AssistantsLink), 200);
      await tester.tap(find.byType(AssistantsLink));
      await tester.pumpAndSettle();
      expect(find.text('the assistants screen'), findsOneWidget);
    });
  }

  for (final isFamily in [true, false]) {
    testWidgets('it holds at phone width in dark at 200% text, for '
        '${isFamily ? 'a parent' : 'a helper'}', (tester) async {
      tester.view.physicalSize = const Size(360 * 3, 800 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await pump(
        tester,
        view: Fixtures.view(
          members: people(7),
          viewerUid: isFamily ? Fixtures.samUid : Fixtures.thandiUid,
        ),
        brightness: Brightness.dark,
        scale: 2,
      );

      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(find.byType(AssistantsLink), 200);
      expect(tester.takeException(), isNull);
    });
  }
}
