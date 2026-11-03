import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/household/data/household_repository.dart';
import 'package:nestprep/features/household/model/household_view.dart';
import 'package:nestprep/features/subscriptions/model/premium_voucher.dart';
import 'package:nestprep/features/subscriptions/ui/premium_voucher_host.dart';
import 'package:nestprep/shared/copy/premium_voucher_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:nestprep/shared/flags/feature_flags_controller.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../../../support/fake_feature_flag_source.dart';
import '../../../support/fake_household.dart';
import '../../../support/fake_premium_vouchers.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/pump_screen.dart';
import '../../../support/pump_subscriptions.dart';

/// The household shell offering Premium that is waiting (subscriptions
/// ADR-0003): once, to family, while the switch is on.
void main() {
  late SubscriptionHarness premium;

  Future<void> openShell(
    WidgetTester tester, {
    List<PremiumVoucher> waiting = const [FakePremiumVoucherDirectory.frame],
    HouseholdView? view,
    bool vouchersOn = true,
    AppFailure? listFails,
  }) async {
    premium = SubscriptionHarness();
    premium.vouchers
      ..waiting = [...waiting]
      ..failListWith = listFails;
    final households = FakeHouseholdRepository();
    addTearDown(households.close);
    await pumpScreen(
      tester,
      const PremiumVoucherHost(child: Text('home')),
      providers: <SingleChildWidget>[
        ...premium.providers,
        Provider<HouseholdRepository>.value(value: households),
        if (!vouchersOn)
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

  testWidgets('opens the claim sheet by itself, and only once', (tester) async {
    await openShell(tester);
    expect(premium.vouchers.listed, 1);
    expect(find.text(PremiumVoucherCopy.sheetTitle), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('voucher-sheet-close')));
    await tester.pumpAndSettle();
    expect(find.text(PremiumVoucherCopy.sheetTitle), findsNothing);

    await premium.inbox.refresh();
    await tester.pumpAndSettle();
    expect(find.text(PremiumVoucherCopy.sheetTitle), findsNothing);
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('with nothing waiting it opens nothing', (tester) async {
    await openShell(tester, waiting: const []);
    expect(premium.vouchers.listed, 1);
    expect(find.text(PremiumVoucherCopy.sheetTitle), findsNothing);
  });

  testWidgets('switched off, it does not even ask', (tester) async {
    await openShell(tester, vouchersOn: false);
    expect(premium.vouchers.listed, 0);
    expect(find.text(PremiumVoucherCopy.sheetTitle), findsNothing);
  });

  testWidgets('a helper is not asked to add Premium', (tester) async {
    await openShell(tester, view: Fixtures.view(viewerUid: Fixtures.thandiUid));
    expect(premium.vouchers.listed, 0);
    expect(find.text(PremiumVoucherCopy.sheetTitle), findsNothing);
  });

  testWidgets('a list it cannot read opens nothing', (tester) async {
    await openShell(tester, listFails: const UnavailableFailure());
    expect(premium.vouchers.listed, 1);
    expect(find.text(PremiumVoucherCopy.sheetTitle), findsNothing);
    expect(find.text('home'), findsOneWidget);
  });
}
