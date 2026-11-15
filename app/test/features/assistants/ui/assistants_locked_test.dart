import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/assistants/state/connected_assistants_controller.dart';
import 'package:nestprep/features/assistants/ui/connected_assistants_screen.dart';
import 'package:nestprep/features/assistants/ui/locked_assistants_screen.dart';
import 'package:nestprep/features/subscriptions/model/premium_feature.dart';
import 'package:nestprep/features/subscriptions/ui/paywall_page.dart';
import 'package:nestprep/features/subscriptions/ui/premium_area.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/copy/subscription_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:nestprep/shared/time/household_clock.dart';
import 'package:provider/provider.dart';

import '../../../support/fake_assistants.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/premium_entitlement.dart';
import '../../../support/pump_screen.dart';
import '../../../support/pump_subscriptions.dart';

/// *Connected assistants* is Premium (subscriptions ADR-0008): a household
/// without it meets the place locked, with no switch and no way to connect —
/// and still sees what is connected, because disconnecting an assistant is
/// never something to pay for.
void main() {
  late FakeAssistantRepository repository;

  setUp(() => repository = FakeAssistantRepository());
  tearDown(() => repository.close());

  Future<SubscriptionHarness> pump(
    WidgetTester tester, {
    String viewerUid = Fixtures.samUid,
    String viewerMemberId = Fixtures.samMemberId,
    bool isFamily = true,
    bool premium = false,
    Brightness brightness = Brightness.light,
    double textScale = 1,
    bool tall = true,
  }) async {
    if (tall) {
      tester.view.physicalSize = const Size(420 * 3, 2400 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
    }
    final subscriptions = SubscriptionHarness();
    final controller = ConnectedAssistantsController(
      assistantRepository: repository,
      householdClock: HouseholdClock(
        'Africa/Johannesburg',
        now: () => assistantsNow,
      ),
      householdId: Fixtures.householdId,
      viewerUid: viewerUid,
      viewerMemberId: viewerMemberId,
      isFamily: isFamily,
    );
    addTearDown(controller.dispose);
    await pumpScreen(
      tester,
      const AssistantsPremiumArea(child: ConnectedAssistantsScreen()),
      providers: [
        ...subscriptions.providers,
        if (premium) premiumEntitlementProvider(),
        ChangeNotifierProvider<ConnectedAssistantsController>.value(
          value: controller,
        ),
      ],
      view: Fixtures.view(viewerUid: viewerUid),
      brightness: brightness,
      textScale: textScale,
    );
    await tester.pump();
    return subscriptions;
  }

  Finder inCard(String connectionId, String text) => find.descendant(
    of: find.byKey(ValueKey(connectionId)),
    matching: find.text(text),
  );

  Future<void> disconnect(WidgetTester tester, String connectionId) async {
    await tester.ensureVisible(inCard(connectionId, AssistantsCopy.disconnect));
    await tester.tap(inCard(connectionId, AssistantsCopy.disconnect));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AssistantsCopy.disconnect).last);
    await tester.pumpAndSettle();
  }

  for (final brightness in Brightness.values) {
    group(brightness.name, () {
      testWidgets('without Premium the place is locked: no switch, no way to '
          'connect, and nothing listed when nothing is connected', (
        tester,
      ) async {
        await pump(tester, brightness: brightness);
        repository
          ..emitConnections([])
          ..emitAllowed(true);
        await tester.pumpAndSettle();

        expect(find.byType(PremiumLockedView), findsOneWidget);
        expect(find.text(AssistantsCopy.title), findsOneWidget);
        expect(
          find.text(SubscriptionCopy.headline(PremiumFeature.assistants)),
          findsOneWidget,
        );
        expect(find.byType(ConnectedAssistantsScreen), findsNothing);
        expect(find.byType(Switch), findsNothing);
        expect(find.text(AssistantsCopy.connectAddress), findsNothing);
        expect(find.text(AssistantsCopy.sectionConnected), findsNothing);
        expect(find.text(AssistantsCopy.emptyTitle), findsNothing);
      });

      testWidgets('what is still connected is listed, and can be '
          'disconnected without Premium', (tester) async {
        await pump(tester, brightness: brightness);
        repository.emitConnections([
          claudeConnection(),
          claudeConnection(
            id: 'g-thandi',
            uid: Fixtures.thandiUid,
            memberId: Fixtures.thandiMemberId,
          ),
        ]);
        await tester.pumpAndSettle();

        expect(find.byType(PremiumLockedView), findsOneWidget);
        expect(find.text(AssistantsCopy.lockedConnectionsBody), findsOneWidget);

        await disconnect(tester, 'g-thandi');

        expect(repository.disconnected, ['g-thandi']);
        expect(find.byType(PaywallPage), findsNothing);
      });
    });
  }

  testWidgets('somebody who is not family disconnects their own, locked or '
      'not', (tester) async {
    await pump(
      tester,
      viewerUid: Fixtures.thandiUid,
      viewerMemberId: Fixtures.thandiMemberId,
      isFamily: false,
    );
    repository.emitConnections([
      claudeConnection(
        id: 'g-thandi',
        uid: Fixtures.thandiUid,
        memberId: Fixtures.thandiMemberId,
      ),
    ]);
    await tester.pumpAndSettle();

    await disconnect(tester, 'g-thandi');
    expect(repository.disconnected, ['g-thandi']);
  });

  testWidgets('a disconnect refused says why in the app’s words', (
    tester,
  ) async {
    await pump(tester);
    repository
      ..emitConnections([claudeConnection()])
      ..failWritesWith = const UnavailableFailure();
    await tester.pumpAndSettle();

    await disconnect(tester, 'g-sam');
    expect(
      find.text(AppCopy.failure(const UnavailableFailure())),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('g-sam')), findsOneWidget);
  });

  testWidgets('See Premium opens the paywall on assistants', (tester) async {
    final subscriptions = await pump(tester);
    repository.emitConnections([]);
    await tester.pumpAndSettle();

    await tester.tap(find.text(SubscriptionCopy.seePremium));
    await tester.pumpAndSettle();

    expect(find.byType(PaywallPage), findsOneWidget);
    expect(
      subscriptions.paywallOpens.opened.single.trigger,
      PremiumFeature.assistants,
    );
  });

  testWidgets('with Premium the place opens whole', (tester) async {
    await pump(tester, premium: true);
    repository
      ..emitConnections([])
      ..emitAllowed(true);
    await tester.pumpAndSettle();

    expect(find.byType(ConnectedAssistantsScreen), findsOneWidget);
    expect(find.byType(PremiumLockedView), findsNothing);
    expect(find.byType(Switch), findsOneWidget);
    expect(find.text(AssistantsCopy.connectAddress), findsOneWidget);
  });

  testWidgets('the locked place, its connections and its paywall hold in '
      'dark at 200% text on a 360-wide phone', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await pump(tester, brightness: Brightness.dark, textScale: 2, tall: false);
    repository
      ..emitConnections([
        claudeConnection(),
        claudeConnection(
          id: 'g-thandi',
          uid: Fixtures.thandiUid,
          memberId: Fixtures.thandiMemberId,
        ),
      ])
      ..emitActivity([assistantActivity('a1')]);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(PremiumLockedView), findsOneWidget);

    await tester.dragUntilVisible(
      find.text(AssistantsCopy.lockedConnectionsBody),
      find.byType(ListView),
      const Offset(0, -200),
    );
    expect(tester.takeException(), isNull);

    await tester.dragUntilVisible(
      find.text(SubscriptionCopy.seePremium),
      find.byType(ListView),
      const Offset(0, 200),
    );
    await tester.tap(find.text(SubscriptionCopy.seePremium));
    await tester.pumpAndSettle();
    expect(find.byType(PaywallPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
