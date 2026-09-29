import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/household/data/invite_sharer.dart';
import 'package:nestprep/features/referrals/data/referral_directory.dart';
import 'package:nestprep/features/referrals/data/referral_repository.dart';
import 'package:nestprep/features/referrals/model/household_referral.dart';
import 'package:nestprep/features/referrals/model/premium_grant.dart';
import 'package:nestprep/features/referrals/model/referral_line.dart';
import 'package:nestprep/shared/flags/feature_flags_controller.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'fake_feature_flag_source.dart';
import 'fake_invite_sharer.dart';
import 'fake_referrals.dart';

/// Everything give a month, get a month needs above a screen, as the app's
/// providers give it (subscriptions ADR-0002): the reads and callables faked,
/// the share sheet faked, and the switch on unless a test says off.
final class ReferralHarness {
  ReferralHarness({
    HouseholdReferral? referral,
    List<ReferralLine> lines = const [],
    List<PremiumGrant> grants = const [],
    bool isOn = true,
  }) : repository = FakeReferralRepository(
         referral: referral,
         lines: lines,
         grants: grants,
       ),
       flags = FeatureFlagsController(
         source: FakeFeatureFlagSource(),
         defaultOn: isOn,
       ) {
    addTearDown(() async {
      flags.dispose();
      await repository.close();
    });
  }

  final FakeReferralRepository repository;
  final directory = FakeReferralDirectory();
  final sharer = FakeInviteSharer();
  final FeatureFlagsController flags;

  List<SingleChildWidget> get providers => [
    ChangeNotifierProvider<FeatureFlagsController>.value(value: flags),
    Provider<ReferralRepository>.value(value: repository),
    Provider<ReferralDirectory>.value(value: directory),
    Provider<InviteSharer>.value(value: sharer),
  ];
}
