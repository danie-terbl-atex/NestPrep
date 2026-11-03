import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/subscriptions/model/entitlement.dart';
import 'package:nestprep/features/subscriptions/model/grant_days_waiting.dart';
import 'package:nestprep/features/subscriptions/ui/premium_time_card.dart';
import 'package:nestprep/shared/copy/premium_voucher_copy.dart';

import '../../../support/pump_kit.dart';

/// The free Premium row's date (subscriptions ADR-0003): it says it counts
/// the waiting time only when some is waiting.
void main() {
  final now = DateTime.utc(2026, 11, 3);
  final until = DateTime.utc(2027, 2, 3);

  Future<void> pumpCard(WidgetTester tester, GrantDaysWaiting waiting) =>
      pumpKit(
        tester,
        PremiumTimeCard(
          entitlement: Entitlement(
            premiumUntil: until,
            grantUntil: until,
            grantDaysWaiting: waiting,
          ),
          now: now,
          dateLabel: (_) => '3 February',
        ),
      );

  testWidgets('with time waiting, the date counts it', (tester) async {
    await pumpCard(tester, const GrantDaysWaiting(frame: 62));
    expect(
      find.text(PremiumVoucherCopy.untilWithWaiting('3 February')),
      findsOneWidget,
    );
    expect(find.text(PremiumVoucherCopy.until('3 February')), findsNothing);
  });

  testWidgets('with nothing waiting, it is the plain date', (tester) async {
    await pumpCard(tester, const GrantDaysWaiting());
    expect(find.text(PremiumVoucherCopy.until('3 February')), findsOneWidget);
    expect(
      find.text(PremiumVoucherCopy.untilWithWaiting('3 February')),
      findsNothing,
    );
  });
}
