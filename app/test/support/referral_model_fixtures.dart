import 'package:nestprep/features/referrals/model/household_referral.dart';
import 'package:nestprep/features/referrals/model/premium_grant.dart';
import 'package:nestprep/features/referrals/model/referral_line.dart';
import 'package:nestprep/features/referrals/model/referral_reward.dart';
import 'package:nestprep/features/referrals/model/referral_side.dart';
import 'package:nestprep/features/referrals/model/referral_status.dart';

import 'model_fixtures.dart';

/// Give a month, get a month's stored models (subscriptions ADR-0002), for
/// the round trip every model's boundary is driven through. Each is written
/// only by a Function, so the round trip is the read the app makes of what
/// the Function stored.
List<ModelFixture> referralModelFixtures(DateTime at) {
  final referral = HouseholdReferral(
    code: 'ABCD2345',
    redeemBy: at,
    hasRedeemed: true,
    yearlyRewardCap: 6,
  );
  final line = ReferralLine(
    id: 'entry-1',
    side: ReferralSide.referrer,
    status: ReferralStatus.qualified,
    redeemedAt: at,
    qualifyBy: at,
    qualifiedAt: at,
    reward: ReferralReward.month,
  );
  final grant = PremiumGrant(
    id: 'referral-entry-1',
    days: 30,
    grantedAt: at,
    startsAt: at,
  );
  const writtenBy =
      'written only by the referral Functions; the rules refuse every client '
      'write (subscriptions ADR-0002).';
  return [
    ModelFixture(
      label: 'HouseholdReferral',
      id: 'current',
      value: referral,
      toJson: referral.toJson,
      fromJson: HouseholdReferral.fromJson,
      keys: const {'code', 'redeemBy', 'hasRedeemed', 'yearlyRewardCap'},
      note: writtenBy,
    ),
    ModelFixture(
      label: 'ReferralLine',
      id: line.id,
      value: line,
      toJson: line.toJson,
      fromJson: ReferralLine.fromJson,
      keys: const {
        'side',
        'status',
        'redeemedAt',
        'qualifyBy',
        'qualifiedAt',
        'reward',
      },
      note: writtenBy,
    ),
    ModelFixture(
      label: 'PremiumGrant',
      id: grant.id,
      value: grant,
      toJson: grant.toJson,
      fromJson: PremiumGrant.fromJson,
      keys: const {'days', 'grantedAt', 'startsAt'},
      note: writtenBy,
    ),
  ];
}
