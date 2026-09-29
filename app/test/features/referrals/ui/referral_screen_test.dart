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
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:provider/provider.dart';

import '../../../support/household_fixtures.dart';
import '../../../support/pump_referrals.dart';
import '../../../support/pump_screen.dart';

/// Give a month, get a month (subscriptions ADR-0002): the code to share, the
/// free months, a code to enter in the first week, and every referral — in
/// loading, error, empty and full, and at 200% text in the dark.
void main() {
  late ReferralHarness referrals;
  final now = DateTime.now().toUtc();

  final newHousehold = HouseholdReferral(
    code: 'ABCD2345',
    redeemBy: now.add(const Duration(days: 5)),
    yearlyRewardCap: 6,
  );

  Future<void> pumpReferrals(
    WidgetTester tester, {
    HouseholdReferral? referral,
    List<ReferralLine> lines = const [],
    List<PremiumGrant> grants = const [],
    Brightness brightness = Brightness.light,
    double textScale = 1,
  }) async {
    referrals = ReferralHarness(
      referral: referral,
      lines: lines,
      grants: grants,
    );
    await pumpScreen(
      tester,
      ChangeNotifierProvider(
        create: (_) => ReferralController(
          referralRepository: referrals.repository,
          referralDirectory: referrals.directory,
          inviteSharer: referrals.sharer,
          householdId: Fixtures.householdId,
        ),
        child: const ReferralScreen(),
      ),
      providers: referrals.providers,
      brightness: brightness,
      textScale: textScale,
    );
    // A card waiting for its code shimmers until it arrives, so a screen
    // without one is pumped past its entrance rather than settled.
    if (referral?.code == null) {
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
    } else {
      await tester.pumpAndSettle();
    }
  }

  /// The screen's own list — the code field has a scrollable of its own.
  Future<void> scrollTo(WidgetTester tester, Finder finder) =>
      tester.scrollUntilVisible(
        finder,
        200,
        scrollable: find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      );

  testWidgets('holds its place while the reads answer', (tester) async {
    referrals = ReferralHarness();
    await pumpScreen(
      tester,
      ChangeNotifierProvider(
        create: (_) => ReferralController(
          referralRepository: referrals.repository,
          referralDirectory: referrals.directory,
          inviteSharer: referrals.sharer,
          householdId: Fixtures.householdId,
        ),
        child: const ReferralScreen(),
      ),
      providers: referrals.providers,
    );
    await tester.pump();
    expect(find.text(ReferralCopy.title), findsOneWidget);
    expect(find.text(ReferralCopy.heroTitle), findsNothing);
  });

  testWidgets('shows the code, and shares it the way an invite leaves', (
    tester,
  ) async {
    await pumpReferrals(tester, referral: newHousehold);
    expect(find.text(ReferralCopy.heroTitle), findsOneWidget);
    expect(find.text('ABCD2345'), findsOneWidget);

    await tester.tap(find.text(ReferralCopy.share));
    await tester.pumpAndSettle();
    expect(referrals.sharer.sent.single.text, contains('ABCD2345'));
    expect(referrals.sharer.sent.single.subject, ReferralCopy.shareSubject);
  });

  testWidgets('asks the server for a code when there is none, and holds the '
      'card while it comes', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpReferrals(tester, referral: HouseholdReferral.none);
    expect(referrals.directory.ensured, [Fixtures.householdId]);
    expect(
      find.bySemanticsLabel(RegExp(RegExp.escape(ReferralCopy.preparingCode))),
      findsOneWidget,
    );

    referrals.repository.emitReferral(newHousehold);
    await tester.pumpAndSettle();
    expect(find.text('ABCD2345'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('says so when the code could not be made, and tries again', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    referrals = ReferralHarness(referral: HouseholdReferral.none);
    referrals.directory.failEnsureWith = const UnavailableFailure();
    await pumpScreen(
      tester,
      ChangeNotifierProvider(
        create: (_) => ReferralController(
          referralRepository: referrals.repository,
          referralDirectory: referrals.directory,
          inviteSharer: referrals.sharer,
          householdId: Fixtures.householdId,
        ),
        child: const ReferralScreen(),
      ),
      providers: referrals.providers,
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(
      find.text(AppCopy.failure(const UnavailableFailure())),
      findsOneWidget,
    );
    referrals.directory.failEnsureWith = null;
    await tester.tap(find.text(AppCopy.retry));
    await tester.pump();
    expect(referrals.directory.ensured, hasLength(2));
    expect(
      find.bySemanticsLabel(RegExp(RegExp.escape(ReferralCopy.preparingCode))),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('a new household enters another family’s code, and a refusal '
      'lands on the field in words', (tester) async {
    tester.view.physicalSize = const Size(420 * 3, 2000 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await pumpReferrals(tester, referral: newHousehold);
    final field = find.byType(TextField);
    await scrollTo(tester, field);
    referrals.directory.failRedeemWith = const ReferralFailure(
      ReferralProblem.ownReferralCode,
    );
    await tester.enterText(field, 'abcd2345');
    await tester.pump();
    await scrollTo(tester, find.text(ReferralCopy.redeemAction));
    await tester.tap(find.text(ReferralCopy.redeemAction));
    await tester.pumpAndSettle();
    expect(
      find.text(ReferralCopy.problem(ReferralProblem.ownReferralCode)),
      findsOneWidget,
    );

    referrals.directory.failRedeemWith = null;
    await tester.enterText(field, 'WXYZ2345');
    await tester.pump();
    expect(
      find.text(ReferralCopy.problem(ReferralProblem.ownReferralCode)),
      findsNothing,
    );
    await tester.tap(find.text(ReferralCopy.redeemAction));
    await tester.pumpAndSettle();
    expect(referrals.directory.redeemed.single.code, 'WXYZ2345');
  });

  testWidgets('does not offer a code to a household past its first week', (
    tester,
  ) async {
    await pumpReferrals(
      tester,
      referral: newHousehold.copyWith(
        redeemBy: now.subtract(const Duration(days: 1)),
      ),
    );
    expect(find.text(ReferralCopy.redeemTitle), findsNothing);
  });

  testWidgets(
    'with no referrals yet, says so under the code that starts them',
    (tester) async {
      await pumpReferrals(tester, referral: newHousehold);
      await scrollTo(tester, find.text(ReferralCopy.noMonthsYet));
      expect(find.text(ReferralCopy.noMonthsYet), findsOneWidget);
      await scrollTo(tester, find.text(ReferralCopy.historyEmpty));
      expect(find.text(ReferralCopy.historyEmpty), findsOneWidget);
    },
  );

  testWidgets('lists every referral as it stands, and the months they gave', (
    tester,
  ) async {
    await pumpReferrals(
      tester,
      referral: newHousehold.copyWith(hasRedeemed: true),
      lines: [
        ReferralLine(
          id: 'pending',
          side: ReferralSide.referrer,
          qualifyBy: now.add(const Duration(days: 9)),
          redeemedAt: now,
        ),
        ReferralLine(
          id: 'paid',
          side: ReferralSide.referrer,
          status: ReferralStatus.qualified,
          reward: ReferralReward.month,
          qualifiedAt: now.subtract(const Duration(days: 2)),
        ),
        ReferralLine(
          id: 'late',
          side: ReferralSide.referrer,
          qualifyBy: now.subtract(const Duration(days: 1)),
        ),
      ],
      grants: [
        PremiumGrant(
          id: 'g1',
          days: 30,
          grantedAt: now.subtract(const Duration(days: 2)),
          startsAt: now.subtract(const Duration(days: 2)),
        ),
      ],
    );
    await scrollTo(tester, find.text(ReferralCopy.monthsThisYear(1, 6)));
    expect(find.text(ReferralCopy.monthsThisYear(1, 6)), findsOneWidget);
    await scrollTo(tester, find.text(ReferralCopy.tagExpired));
    expect(find.text(ReferralCopy.tagPending), findsOneWidget);
    expect(find.text(ReferralCopy.tagMonth), findsOneWidget);
    expect(find.text(ReferralCopy.lineExpired), findsOneWidget);
  });

  testWidgets('says when the year’s months are used up', (tester) async {
    await pumpReferrals(
      tester,
      referral: newHousehold.copyWith(yearlyRewardCap: 1),
      grants: [
        PremiumGrant(
          id: 'g1',
          days: 30,
          grantedAt: now.subtract(const Duration(days: 40)),
          startsAt: now.subtract(const Duration(days: 40)),
        ),
      ],
    );
    await scrollTo(tester, find.text(ReferralCopy.capReached));
    expect(find.text(ReferralCopy.capReached), findsOneWidget);
  });

  testWidgets('a read it cannot make is an error with a retry', (tester) async {
    await pumpReferrals(tester, referral: newHousehold);
    referrals.repository.failHistory(const PermissionDeniedFailure());
    await tester.pumpAndSettle();
    expect(
      find.text(AppCopy.failure(const PermissionDeniedFailure())),
      findsOneWidget,
    );
    await tester.tap(find.text(AppCopy.retry));
    await tester.pumpAndSettle();
    expect(find.text('ABCD2345'), findsOneWidget);
  });

  testWidgets('survives dark at 200% text on a 360-wide phone', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await pumpReferrals(
      tester,
      referral: newHousehold,
      lines: [
        ReferralLine(
          id: 'paid',
          side: ReferralSide.referrer,
          status: ReferralStatus.qualified,
          reward: ReferralReward.capped,
          qualifiedAt: now,
        ),
      ],
      brightness: Brightness.dark,
      textScale: 2,
    );
    await scrollTo(tester, find.text(ReferralCopy.tagCapped));
    expect(tester.takeException(), isNull);
  });
}
