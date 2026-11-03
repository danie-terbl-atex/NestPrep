import 'package:flutter/widgets.dart';

import '../../../design/nest_kit.dart';
import '../model/family_place.dart';

abstract final class PlaceLook {
  static IconData icon(PlaceIcon icon) => switch (icon) {
    PlaceIcon.home => LucideIcons.house,
    PlaceIcon.school => LucideIcons.school,
    PlaceIcon.work => LucideIcons.briefcase,
    PlaceIcon.sport => LucideIcons.trophy,
    PlaceIcon.shop => LucideIcons.shoppingBag,
    PlaceIcon.family => LucideIcons.heart,
    PlaceIcon.other => LucideIcons.mapPin,
  };
}
