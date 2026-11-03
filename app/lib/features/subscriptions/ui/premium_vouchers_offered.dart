import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../../shared/flags/feature_flag.dart';
import '../../../shared/flags/feature_flags_controller.dart';
import '../../household/model/household_view.dart';

bool premiumVouchersOffered(BuildContext context, {bool listen = true}) =>
    Provider.of<FeatureFlagsController>(
      context,
      listen: listen,
    ).isOn(FeatureFlag.premiumVouchers) &&
    Provider.of<HouseholdView>(context, listen: listen).permissions.isFamily;
