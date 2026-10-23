import 'package:flutter/widgets.dart';

import '../../../design/nest_kit.dart';
import '../../groceries/model/product_match.dart';

/// A shop's own logo, from `assets/retailers/` (add-to-checkers ADR-0006):
/// the Sixty60 app mark for Checkers, because Sixty60 is the shop NestPrep
/// talks to. [RetailerLogo.decorative] is the logo alone, where the words
/// beside it already name the shop ([NestLogoTile.decorative]).
class RetailerLogo extends StatelessWidget {
  const RetailerLogo({
    required this.retailer,
    required String this.label,
    this.onTap,
    this.size = NestSize.logoSmall,
    this.tone = NestLogoTileTone.idle,
    super.key,
  });

  const RetailerLogo.decorative({
    required this.retailer,
    this.size = NestSize.logoSmall,
    super.key,
  }) : label = null,
       onTap = null,
       tone = NestLogoTileTone.idle;

  final ProductRetailer retailer;
  final String? label;
  final VoidCallback? onTap;
  final double size;
  final NestLogoTileTone tone;

  static String assetFor(ProductRetailer retailer) => switch (retailer) {
    ProductRetailer.checkers => 'assets/retailers/checkers_sixty60.png',
    ProductRetailer.pickNPay => 'assets/retailers/pick_n_pay.png',
    ProductRetailer.woolworths => 'assets/retailers/woolworths.png',
  };

  @override
  Widget build(BuildContext context) {
    final label = this.label;
    if (label == null) {
      return NestLogoTile.decorative(asset: assetFor(retailer), size: size);
    }
    return NestLogoTile(
      asset: assetFor(retailer),
      label: label,
      onTap: onTap,
      size: size,
      tone: tone,
    );
  }
}
