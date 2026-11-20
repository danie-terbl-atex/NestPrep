import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/household/data/household_repository.dart';
import 'package:nestprep/features/household/model/household_view.dart';
import 'package:nestprep/features/subscriptions/ui/premium_voucher_host.dart';
import 'package:nestprep/features/subscriptions/ui/premium_vouchers_offered.dart';
import 'package:nestprep/shared/copy/premium_voucher_copy.dart';
import 'package:nestprep/shared/flags/feature_flags_controller.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../../../support/fake_feature_flag_source.dart';
import '../../../support/fake_household.dart';
import '../../../support/fake_premium_vouchers.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/pump_screen.dart';
import '../../../support/pump_subscriptions.dart';

/// Which platforms offer waiting Premium with the cloud switch off
/// (subscriptions ADR-0011).
void main() {
  late SubscriptionHarness premium;

  Future<void> openShellSwitchedOff(
    WidgetTester tester, {
    HouseholdView? view,
  }) async {
    premium = SubscriptionHarness();
    premium.vouchers.waiting = [FakePremiumVoucherDirectory.frame];
    final households = FakeHouseholdRepository();
    addTearDown(households.close);
    await pumpScreen(
      tester,
      const PremiumVoucherHost(child: Text('home')),
      providers: <SingleChildWidget>[
        ...premium.providers,
        Provider<HouseholdRepository>.value(value: households),
        ChangeNotifierProvider<FeatureFlagsController>(
          create: (_) => FeatureFlagsController(
            source: FakeFeatureFlagSource(),
            defaultOn: false,
          ),
        ),
      ],
      view: view,
    );
    await tester.pumpAndSettle();
  }

  setUp(() => debugPremiumVouchersAlwaysOn = null);
  tearDown(() {
    debugPremiumVouchersAlwaysOn = const {};
    debugDefaultTargetPlatformOverride = null;
  });

  test('the source holds vouchers on for Android only', () {
    expect(premiumVouchersAlwaysOn, {TargetPlatform.android});
  });

  testWidgets('Android offers with the cloud switch off', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await openShellSwitchedOff(tester);
    expect(premium.vouchers.listed, 1);
    expect(find.text(PremiumVoucherCopy.sheetTitle), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('iOS still follows the cloud switch', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await openShellSwitchedOff(tester);
    expect(premium.vouchers.listed, 0);
    expect(find.text(PremiumVoucherCopy.sheetTitle), findsNothing);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('a helper on Android is still not asked', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await openShellSwitchedOff(
      tester,
      view: Fixtures.view(viewerUid: Fixtures.thandiUid),
    );
    expect(premium.vouchers.listed, 0);
    expect(find.text(PremiumVoucherCopy.sheetTitle), findsNothing);
    debugDefaultTargetPlatformOverride = null;
  });
}
