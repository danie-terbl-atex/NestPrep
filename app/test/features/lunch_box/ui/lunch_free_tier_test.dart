import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/lunch_box/model/lunch_pick.dart';
import 'package:nestprep/features/lunch_box/model/lunch_slot.dart';
import 'package:nestprep/features/lunch_box/ui/lunch_screen.dart';
import 'package:nestprep/features/subscriptions/model/free_child.dart';
import 'package:nestprep/features/subscriptions/model/premium_feature.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/copy/subscription_copy.dart';

import '../../../support/lunch_fixtures.dart';
import '../../../support/lunch_harness.dart';
import '../../../support/pump_screen.dart';

/// Where lunch-box's free tier ends, on screen (lunch-box ADR-0009): a free
/// household plans the one child its first marking recorded, and meets the
/// paywall — opened on that very thing — on another child's week, on
/// marking what came home, and on the Sunday prep list. The rules refuse
/// all three regardless; this is the answer before anything is written.
void main() {
  late LunchHarness harness;

  setUp(
    () => harness = LunchHarness(
      isPremium: false,
      freeChild: const FreeChild(LunchFixtures.lwaziId),
    ),
  );
  tearDown(() => harness.close());

  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(420 * 3, 2400 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await pumpScreen(
      tester,
      LunchScreen(onSelectTab: (_) {}),
      providers: harness.providers,
    );
    harness.emit(
      plans: [
        LunchFixtures.plan(
          LunchFixtures.lwaziId,
          slots: {
            LunchFixtures.key(1, LunchSlot.main): LunchPick.of(
              LunchFixtures.wrap,
            ),
          },
        ),
      ],
    );
    await tester.pumpAndSettle();
  }

  Finder paywallOn(PremiumFeature feature) =>
      find.text(SubscriptionCopy.headline(feature));

  testWidgets('plans the free child’s week as ever', (tester) async {
    await open(tester);
    await tester.tap(find.text(LunchCopy.addToSlot(LunchSlot.fruit)).first);
    await tester.pumpAndSettle();
    expect(find.text(LunchCopy.suggestedFor('Lwazi')), findsOneWidget);
    expect(paywallOn(PremiumFeature.additionalChild), findsNothing);
  });

  testWidgets('another child’s week opens premium, and writes nothing', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.text('Ayanda'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(LunchCopy.fillWeek));
    await tester.pumpAndSettle();
    expect(paywallOn(PremiumFeature.additionalChild), findsOneWidget);
    expect(harness.repository.writtenPicks, isEmpty);
  });

  testWidgets('marking what came home opens premium on the learning loop', (
    tester,
  ) async {
    await open(tester);
    await tester.ensureVisible(find.text(LunchCopy.ateIt).first);
    await tester.tap(find.text(LunchCopy.ateIt).first);
    await tester.pumpAndSettle();
    expect(paywallOn(PremiumFeature.lunchLearning), findsOneWidget);
    expect(harness.repository.writtenFeedback, isEmpty);
  });

  testWidgets('the Sunday prep list opens premium instead of the list', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.text(LunchCopy.openPrep));
    await tester.pumpAndSettle();
    expect(paywallOn(PremiumFeature.prepList), findsOneWidget);
  });
}
