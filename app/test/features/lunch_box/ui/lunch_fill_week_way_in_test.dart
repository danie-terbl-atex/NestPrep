import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nestprep/app/lunch_route.dart';
import 'package:nestprep/features/lunch_box/ui/lunch_screen.dart';
import 'package:nestprep/features/subscriptions/model/free_child.dart';
import 'package:nestprep/features/subscriptions/model/premium_feature.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/copy/subscription_copy.dart';
import 'package:nestprep/shared/flags/feature_flags_controller.dart';
import 'package:provider/provider.dart';

import '../../../support/bring_into_view.dart';
import '../../../support/lunch_fixtures.dart';
import '../../../support/lunch_harness.dart';
import '../../../support/pump_screen.dart';
import '../../../support/test_flags.dart';

/// The board's way into *Fill the week* (lunch-box ADR-0020): for a free
/// household's one free child it opens the flow — free — and writes nothing
/// on the way; for another child the paywall comes first and the flow does
/// not open (ADR-0009).
void main() {
  late LunchHarness harness;
  late FeatureFlagsController flagsOff;

  setUp(() {
    harness = LunchHarness(
      isPremium: false,
      freeChild: const FreeChild(LunchFixtures.lwaziId),
    );
    flagsOff = testFlagsController(TestFlags.off);
  });
  tearDown(() async {
    flagsOff.dispose();
    await harness.close();
  });

  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(420 * 3, 2400 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await pumpRouter(
      tester,
      router: GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => LunchScreen(onSelectTab: (_) {}),
          ),
          GoRoute(
            path: LunchRoute.fillWeekPath,
            builder: (context, state) => Text(
              'flow for ${state.uri.queryParameters[LunchRoute.childQuery]}',
            ),
          ),
        ],
      ),
      providers: [
        ChangeNotifierProvider<FeatureFlagsController>.value(value: flagsOff),
        ...harness.providers,
      ],
    );
    harness.emit();
    await tester.pumpAndSettle();
  }

  Future<void> tapFillWeek(WidgetTester tester) async {
    await bringIntoView(tester, find.text(LunchCopy.fillWeek));
    await tester.tap(find.text(LunchCopy.fillWeek));
    await tester.pumpAndSettle();
  }

  testWidgets('the free child\'s *Fill the week* opens the flow, and writes '
      'nothing until it is used', (tester) async {
    await open(tester);
    await tapFillWeek(tester);
    expect(find.text('flow for ${LunchFixtures.lwaziId}'), findsOneWidget);
    expect(
      find.text(SubscriptionCopy.headline(PremiumFeature.additionalChild)),
      findsNothing,
    );
    expect(harness.repository.writtenPicks, isEmpty);
  });

  testWidgets('another child meets the paywall first, and the flow does not '
      'open', (tester) async {
    await open(tester);
    await tester.tap(find.text('Ayanda'));
    await tester.pumpAndSettle();
    await tapFillWeek(tester);
    expect(
      find.text(SubscriptionCopy.headline(PremiumFeature.additionalChild)),
      findsOneWidget,
    );
    expect(find.textContaining('flow for'), findsNothing);
  });
}
