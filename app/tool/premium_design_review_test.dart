import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/app/household_shell.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/household/ui/household_more_screen.dart';
import 'package:nestprep/features/subscriptions/ui/premium_lockup.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../test/support/premium_entitlement.dart';
import 'review_press.dart';

/// How a Premium household is told (subscriptions ADR-0007) in the
/// design-review press: the card at the top of More with the bar's trim, and
/// the seal beside the wordmark as Today's header carries it — both themes,
/// and at 200% text in the dark. Regenerate with
///
///     flutter test tool/premium_design_review_test.dart --update-goldens
void main() {
  setUpAll(() async {
    tz_data.initializeTimeZones();
    await loadEveryFont();
  });

  Future<void> capture(
    WidgetTester tester,
    String name,
    Widget screen, {
    required Brightness brightness,
    double textScale = 1,
  }) => captureScreen(
    tester,
    name,
    brightness: brightness,
    textScale: textScale,
    screen: screen,
    providers: [premiumEntitlementProvider()],
    emit: () async {},
  );

  final more = HouseholdMoreScreen(onSelectTab: (_) {});
  final home = NestScaffold(
    leading: const PremiumLockup(),
    trailing: [
      NestIconButton(
        icon: LucideIcons.bell,
        label: 'Notifications',
        onPressed: () {},
      ),
    ],
    bottomBar: HouseholdTabBar(current: HouseholdTab.today, onSelect: (_) {}),
    body: const SizedBox.shrink(),
  );

  for (final brightness in Brightness.values) {
    final theme = brightness.name;

    testWidgets('premium-more-$theme', (tester) async {
      await capture(
        tester,
        'premium-more-$theme',
        more,
        brightness: brightness,
      );
    });

    testWidgets('premium-home-header-$theme', (tester) async {
      await capture(
        tester,
        'premium-home-header-$theme',
        home,
        brightness: brightness,
      );
    });
  }

  testWidgets('premium-more-dark-200-percent-text', (tester) async {
    await capture(
      tester,
      'premium-more-dark-200-percent-text',
      more,
      brightness: Brightness.dark,
      textScale: 2,
    );
  });
}
