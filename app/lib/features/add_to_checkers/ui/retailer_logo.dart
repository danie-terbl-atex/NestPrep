import 'package:flutter/widgets.dart';

import '../../../design/nest_kit.dart';
import '../../groceries/model/product_match.dart';

/// A shop's own logo, from `assets/retailers/` (add-to-checkers ADR-0006):
/// the Sixty60 app mark for Checkers, because Sixty60 is the shop NestPrep
/// talks to.
class RetailerLogo extends StatelessWidget {
  const RetailerLogo({
    required this.retailer,
    required this.label,
    this.onTap,
    this.size = NestSize.logoSmall,
    this.tone = NestLogoTileTone.idle,
    super.key,
  });

  final ProductRetailer retailer;
  final String label;
  final VoidCallback? onTap;
  final double size;
  final NestLogoTileTone tone;

  static String assetFor(ProductRetailer retailer) => switch (retailer) {
    ProductRetailer.checkers => 'assets/retailers/checkers_sixty60.png',
    ProductRetailer.pickNPay => 'assets/retailers/pick_n_pay.png',
    ProductRetailer.woolworths => 'assets/retailers/woolworths.png',
  };

  @override
  Widget build(BuildContext context) => NestLogoTile(
    asset: assetFor(retailer),
    label: label,
    onTap: onTap,
    size: size,
    tone: tone,
  );
}
