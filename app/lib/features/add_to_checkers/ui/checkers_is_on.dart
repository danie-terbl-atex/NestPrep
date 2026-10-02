import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../../shared/flags/feature_flag.dart';
import '../../../shared/flags/feature_flags_controller.dart';
import '../state/product_match_controller.dart';

/// Whether the grocery screen shows anything of Checkers: the `addToCheckers`
/// switch is on and the route provided the Checkers controllers. A screen
/// pumped without them — or a build with the switch off — is the plain list.
///
/// [listen] false for an event handler, which must not subscribe.
bool isCheckersOn(BuildContext context, {bool listen = true}) =>
    Provider.of<FeatureFlagsController>(
      context,
      listen: listen,
    ).isOn(FeatureFlag.addToCheckers) &&
    Provider.of<ProductMatchController?>(context, listen: false) != null;
