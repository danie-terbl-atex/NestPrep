import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../../shared/flags/feature_flag.dart';
import '../../../shared/flags/feature_flags_controller.dart';
import '../../household/model/household_view.dart';

/// Whether *give a month, get a month* is offered to the person looking:
/// switched on (foundation ADR-0014) and they are family, who share and enter
/// codes (subscriptions ADR-0002). The rules and the Functions decide for
/// real; this only keeps the way in off screens that would be refused
/// (`FE-04`).
///
/// In a build it [listen]s, so a switch flipped in the console takes effect
/// at once; from a callback — opening the paywall — it only reads.
bool referralsOffered(BuildContext context, {bool listen = true}) =>
    Provider.of<FeatureFlagsController>(
      context,
      listen: listen,
    ).isOn(FeatureFlag.referralRewards) &&
    Provider.of<HouseholdView>(context, listen: listen).permissions.isFamily;
