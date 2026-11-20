import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../../shared/flags/feature_flag.dart';
import '../../../shared/flags/feature_flags_controller.dart';
import '../../household/model/household_view.dart';

/// The platforms that offer waiting Premium whatever `appConfig/flags` says
/// (subscriptions ADR-0011): the cloud switch is held off for App Review
/// 3.1.1, which must not cost an Android frame buyer their months. In source
/// and never a define, so a Shorebird patch can change it.
const premiumVouchersAlwaysOn = {TargetPlatform.android};

@visibleForTesting
Set<TargetPlatform>? debugPremiumVouchersAlwaysOn;

bool premiumVouchersOffered(BuildContext context) =>
    ((debugPremiumVouchersAlwaysOn ?? premiumVouchersAlwaysOn).contains(
          defaultTargetPlatform,
        ) ||
        context.watch<FeatureFlagsController>().isOn(
          FeatureFlag.premiumVouchers,
        )) &&
    context.watch<HouseholdView>().permissions.isFamily;
