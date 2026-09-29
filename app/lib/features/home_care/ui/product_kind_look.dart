import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../model/product_kind.dart';
import '../model/safety/safety_catalogue.dart';

/// How a kind of product looks in a list: an icon, and a warm tint for the
/// ones the catalogue treats as dangerous in themselves. The kind's name is
/// always beside it (`FE-13`).
extension ProductKindLook on ProductKind {
  IconData get icon => switch (this) {
    ProductKind.bleach ||
    ProductKind.peroxide ||
    ProductKind.disinfectant => Icons.sanitizer_outlined,
    ProductKind.ammonia ||
    ProductKind.alcohol ||
    ProductKind.acidic => Icons.science_outlined,
    ProductKind.ovenCleaner => Icons.microwave_outlined,
    ProductKind.drainCleaner => Icons.plumbing_outlined,
    ProductKind.allPurpose ||
    ProductKind.floorCleaner => Icons.cleaning_services_outlined,
    ProductKind.dishSoap => Icons.soap_outlined,
    ProductKind.bicarbonate => Icons.grain_outlined,
    ProductKind.polish => Icons.auto_awesome_outlined,
    ProductKind.other => Icons.inventory_2_outlined,
  };

  NestTileTint get tint => SafetyCatalogue.isHazardous(this)
      ? NestTileTint.peach
      : NestTileTint.mint;
}
