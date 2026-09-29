import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/referrals/model/household_referral.dart';
import 'package:nestprep/features/referrals/model/premium_grant.dart';
import 'package:nestprep/features/referrals/model/referral_line.dart';
import 'package:nestprep/features/referrals/model/referral_overview.dart';
import 'package:nestprep/features/referrals/model/referral_side.dart';
import 'package:nestprep/features/referrals/model/referral_status.dart';
import 'package:nestprep/features/subscriptions/model/entitlement.dart';
import 'package:nestprep/features/subscriptions/model/entitlement_status.dart';

/// What the referral screen reads out of what the server wrote
/// (subscriptions ADR-0002).
void main() {
  final now = DateTime.utc(2026, 10, 10, 9);

  group('a referral line', () {
    test('reads as expired once its deadline passes while still pending', () {
      final line = ReferralLine(
        id: 'l1',
        qualifyBy: now.subtract(const Duration(minutes: 1)),
      );
      expect(line.statusAt(now), ReferralStatus.expired);
      expect(
        line.statusAt(now.subtract(const Duration(hours: 1))),
        ReferralStatus.pending,
      );
    });

    test('keeps what the server said once it has said it', () {
      final line = ReferralLine(
        id: 'l1',
        status: ReferralStatus.qualified,
        qualifyBy: now.subtract(const Duration(days: 3)),
      );
      expect(line.statusAt(now), ReferralStatus.qualified);
    });

    test('reads a status or side this build does not know as the safe one', () {
      final line = ReferralLine.fromJson({
        'id': 'l1',
        'status': 'somethingNew',
        'side': 'somethingElse',
        'reward': 'aYear',
      });
      expect(line.status, ReferralStatus.pending);
      expect(line.side, ReferralSide.referred);
      expect(line.reward, isNull);
    });
  });

  group('the household’s own referral', () {
    test(
      'offers to enter a code until its first week ends, and never twice',
      () {
        final open = HouseholdReferral(
          redeemBy: now.add(const Duration(days: 2)),
        );
        expect(open.canRedeemAt(now), isTrue);
        expect(open.copyWith(hasRedeemed: true).canRedeemAt(now), isFalse);
        expect(open.canRedeemAt(now.add(const Duration(days: 3))), isFalse);
        expect(HouseholdReferral.none.canRedeemAt(now), isFalse);
      },
    );
  });

  group('a granted month', () {
    final started = PremiumGrant(
      id: 'g1',
      days: 30,
      grantedAt: now.subtract(const Duration(days: 5)),
      startsAt: now.subtract(const Duration(days: 5)),
    );

    test('runs its thirty days from its start', () {
      expect(started.isRunningAt(now), isTrue);
      expect(started.endsAt, now.add(const Duration(days: 25)));
      expect(started.isRunningAt(now.add(const Duration(days: 25))), isFalse);
    });

    test('waits while it has no start', () {
      final waiting = PremiumGrant(id: 'g2', days: 30, grantedAt: now);
      expect(waiting.isWaiting, isTrue);
      expect(waiting.isRunningAt(now), isFalse);
    });

    test('counts toward the year, which forgets a month over a year old', () {
      final overview = ReferralOverview(
        referral: const HouseholdReferral(yearlyRewardCap: 2),
        lines: const [],
        grants: [
          started,
          PremiumGrant(id: 'g2', days: 30, grantedAt: now),
          PremiumGrant(
            id: 'g0',
            days: 30,
            grantedAt: now.subtract(const Duration(days: 400)),
            startsAt: now.subtract(const Duration(days: 400)),
          ),
        ],
      );
      expect(overview.monthsThisYear(now), 2);
      expect(overview.hasReachedCapAt(now), isTrue);
      expect(overview.runningAt(now), started);
      expect(overview.monthsWaiting, 1);
    });
  });

  group('an entitlement with given months', () {
    test('is premium that no store sold when only a grant covers it', () {
      final given = Entitlement(premiumUntil: now.add(const Duration(days: 9)));
      expect(given.isGivenOnlyAt(now), isTrue);
      expect(
        given.copyWith(status: EntitlementStatus.active).isGivenOnlyAt(now),
        isFalse,
      );
    });

    test('says waiting days as whole months, a part rounded up', () {
      expect(
        const Entitlement(referralDaysWaiting: 30).referralMonthsWaiting,
        1,
      );
      expect(
        const Entitlement(referralDaysWaiting: 31).referralMonthsWaiting,
        2,
      );
      expect(const Entitlement().referralMonthsWaiting, 0);
    });
  });
}
