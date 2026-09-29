import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/referrals/model/household_referral.dart';
import 'package:nestprep/features/referrals/model/premium_grant.dart';
import 'package:nestprep/features/referrals/model/referral_line.dart';
import 'package:nestprep/features/referrals/model/referral_reward.dart';
import 'package:nestprep/features/referrals/model/referral_side.dart';
import 'package:nestprep/features/referrals/model/referral_status.dart';
import 'package:nestprep/features/referrals/state/referral_controller.dart';
import 'package:nestprep/features/referrals/ui/referral_screen.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../test/support/household_fixtures.dart';
import '../test/support/pump_referrals.dart';
import 'review_press.dart';

/// Give a month, get a month in the design-review press (subscriptions
/// ADR-0002): a household in its first week with a month already earned, a
/// referral settling in and one paid out — the top of the screen, and its
/// history — in both themes, and at 200% text in the dark. Pictures to look
/// at rather than assertions: regenerate with
///
///     flutter test tool/referrals_design_review_test.dart --update-goldens
void main() {
  setUpAll(() async {
    tz_data.initializeTimeZones();
    await loadEveryFont();
  });

  final now = DateTime.now().toUtc();

  ReferralHarness midway() => ReferralHarness(
    referral: HouseholdReferral(
      code: 'HK7Q4MPX',
      redeemBy: now.add(const Duration(days: 4)),
      yearlyRewardCap: 6,
    ),
    lines: [
      ReferralLine(
        id: 'settling',
        side: ReferralSide.referrer,
        redeemedAt: now.subtract(const Duration(days: 1)),
        qualifyBy: now.add(const Duration(days: 13)),
      ),
      ReferralLine(
        id: 'paid',
        side: ReferralSide.referrer,
        status: ReferralStatus.qualified,
        reward: ReferralReward.month,
        redeemedAt: now.subtract(const Duration(days: 6)),
        qualifiedAt: now.subtract(const Duration(days: 3)),
      ),
    ],
    grants: [
      PremiumGrant(
        id: 'g1',
        days: 30,
        grantedAt: now.subtract(const Duration(days: 3)),
        startsAt: now.subtract(const Duration(days: 3)),
      ),
    ],
  );

  Future<void> captureReferrals(
    WidgetTester tester,
    String name, {
    required Brightness brightness,
    double textScale = 1,
    bool showHistory = false,
  }) async {
    final referrals = midway();
    await captureScreen(
      tester,
      name,
      brightness: brightness,
      textScale: textScale,
      screen: ChangeNotifierProvider(
        create: (_) => ReferralController(
          referralRepository: referrals.repository,
          referralDirectory: referrals.directory,
          inviteSharer: referrals.sharer,
          householdId: Fixtures.householdId,
        ),
        child: const ReferralScreen(),
      ),
      providers: referrals.providers,
      emit: () async {},
      // Down past the promise and the code to the months, how it works and
      // the history.
      act: showHistory
          ? () =>
                tester.drag(find.byType(ListView).first, const Offset(0, -900))
          : null,
    );
  }

  for (final brightness in Brightness.values) {
    final theme = brightness.name;

    testWidgets('referrals-$theme', (tester) async {
      await captureReferrals(
        tester,
        'referrals-$theme',
        brightness: brightness,
      );
    });

    testWidgets('referrals-history-$theme', (tester) async {
      await captureReferrals(
        tester,
        'referrals-history-$theme',
        brightness: brightness,
        showHistory: true,
      );
    });
  }

  testWidgets('referrals-dark-200-percent-text', (tester) async {
    await captureReferrals(
      tester,
      'referrals-dark-200-percent-text',
      brightness: Brightness.dark,
      textScale: 2,
    );
  });
}
