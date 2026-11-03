import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../../shared/flags/feature_flag.dart';
import '../../../shared/flags/feature_flags_controller.dart';
import '../../household/model/household_view.dart';

bool premiumVouchersOffered(BuildContext context) =>
    context.watch<FeatureFlagsController>().isOn(FeatureFlag.premiumVouchers) &&
    context.watch<HouseholdView>().permissions.isFamily;
