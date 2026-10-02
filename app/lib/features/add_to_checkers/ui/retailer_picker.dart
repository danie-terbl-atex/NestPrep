import 'package:flutter/widgets.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/checkers_copy.dart';
import '../../groceries/model/product_match.dart';
import 'retailer_logo.dart';

/// *Shop at*: one compact row — the chosen shop by name, and every shop's
/// logo with the chosen one ringed and ticked. A shop that is not connected
/// yet is grey, cannot be chosen, and the words beside the logos say it is
/// coming (`FE-13`). Renders what it is given and reports a tap (`FE-03`).
class RetailerPicker extends StatelessWidget {
  const RetailerPicker({
    required this.chosen,
    required this.onChoose,
    super.key,
  });

  final ProductRetailer chosen;
  final ValueChanged<ProductRetailer> onChoose;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final coming = [
      for (final retailer in ProductRetailer.values)
        if (!retailer.isConnected) retailer,
    ];
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                CheckersCopy.shopAtRetailer(chosen),
                style: nest.text.bodyStrong.copyWith(color: nest.colors.ink),
              ),
              if (coming.isNotEmpty)
                Text(
                  CheckersCopy.comingSoon(coming),
                  style: nest.text.caption.copyWith(
                    color: nest.colors.inkTertiary,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: NestSpace.sm),
        for (final retailer in ProductRetailer.values)
          RetailerLogo(
            retailer: retailer,
            size: NestSize.logoMedium,
            label: retailer.isConnected
                ? CheckersCopy.retailerName(retailer)
                : CheckersCopy.retailerSoon(retailer),
            tone: !retailer.isConnected
                ? NestLogoTileTone.muted
                : retailer == chosen
                ? NestLogoTileTone.selected
                : NestLogoTileTone.idle,
            onTap: retailer.isConnected ? () => onChoose(retailer) : null,
          ),
      ],
    );
  }
}
