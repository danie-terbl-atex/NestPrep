import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../../shared/flags/feature_flags_controller.dart';
import '../../groceries/model/product_match.dart';
import '../model/retailer_switch.dart';
import '../state/product_match_controller.dart';

/// The shops the grocery screen works with now (add-to-pnp ADR-0007): each
/// connected shop whose switch is on, provided the route gave the shop
/// controllers. Empty for a screen pumped without them, or a build with every
/// shop switched off — the plain list.
///
/// [listen] false for an event handler, which must not subscribe.
List<ProductRetailer> shopsOnList(BuildContext context, {bool listen = true}) {
  if (Provider.of<ProductMatchController?>(context, listen: false) == null) {
    return const [];
  }
  final flags = Provider.of<FeatureFlagsController>(context, listen: listen);
  return shopsOn(flags.isOn);
}
