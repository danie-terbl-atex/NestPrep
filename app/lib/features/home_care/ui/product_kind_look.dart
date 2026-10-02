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
    ProductKind.disinfectant => LucideIcons.sprayCan,
    ProductKind.ammonia ||
    ProductKind.alcohol ||
    ProductKind.acidic => LucideIcons.flaskConical,
    ProductKind.ovenCleaner => LucideIcons.microwave,
    ProductKind.drainCleaner => LucideIcons.wrench,
    ProductKind.allPurpose || ProductKind.floorCleaner => LucideIcons.sprayCan,
    ProductKind.dishSoap => LucideIcons.droplets,
    ProductKind.bicarbonate => LucideIcons.wheat,
    ProductKind.polish => LucideIcons.sparkles,
    ProductKind.other => LucideIcons.archive,
  };

  NestTileTint get tint => SafetyCatalogue.isHazardous(this)
      ? NestTileTint.butter
      : NestTileTint.basil;
}
