import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../../shared/flags/feature_flags_controller.dart';
import '../../add_to_checkers/model/retailer_switch.dart';
import '../model/premium_highlight.dart';

/// The Premium areas this build can deliver: shops are left out while no
/// shop is offered (shops ADR-0003), so nothing is sold that cannot be used.
List<PremiumHighlight> highlightsOffered(BuildContext context) {
  final flags = context.watch<FeatureFlagsController?>();
  final noShop = flags != null && shopsOn(flags.isOn).isEmpty;
  return [
    for (final highlight in PremiumHighlight.values)
      if (!noShop || highlight != PremiumHighlight.shops) highlight,
  ];
}
