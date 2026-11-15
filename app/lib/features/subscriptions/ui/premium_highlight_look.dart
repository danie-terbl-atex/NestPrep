import 'package:flutter/widgets.dart';

import '../../../design/nest_kit.dart';
import '../model/premium_highlight.dart';

/// How each Premium area is drawn: its glyph, its accent and, where the
/// brand has one, its mood photo (concept art, never a household's own).
extension PremiumHighlightLook on PremiumHighlight {
  IconData get icon => switch (this) {
    PremiumHighlight.lunches => LucideIcons.sandwich,
    PremiumHighlight.recipes => LucideIcons.chefHat,
    PremiumHighlight.shops => LucideIcons.shoppingCart,
    PremiumHighlight.snaps => LucideIcons.camera,
    PremiumHighlight.whereWeAre => LucideIcons.mapPin,
    PremiumHighlight.nannyHub => LucideIcons.heartHandshake,
    PremiumHighlight.homeCare => LucideIcons.sprayCan,
    PremiumHighlight.twoHomes => LucideIcons.house,
    PremiumHighlight.documents => LucideIcons.folderLock,
    PremiumHighlight.keepsakes => LucideIcons.palette,
    PremiumHighlight.assistants => LucideIcons.messagesSquare,
    PremiumHighlight.household => LucideIcons.users,
  };

  NestTileTint get tint => switch (index % 4) {
    0 => NestTileTint.guava,
    1 => NestTileTint.butter,
    2 => NestTileTint.lilac,
    _ => NestTileTint.basil,
  };

  String? get photo => switch (this) {
    PremiumHighlight.lunches => NestImagery.welcomeLunch,
    PremiumHighlight.recipes => NestImagery.premiumRecipes,
    PremiumHighlight.shops => NestImagery.premiumShops,
    PremiumHighlight.whereWeAre => NestImagery.premiumWhereWeAre,
    PremiumHighlight.nannyHub => NestImagery.premiumNannyHub,
    PremiumHighlight.homeCare => NestImagery.premiumHomeCare,
    PremiumHighlight.twoHomes => NestImagery.premiumTwoHomes,
    PremiumHighlight.documents => NestImagery.premiumDocuments,
    PremiumHighlight.snaps ||
    PremiumHighlight.keepsakes ||
    PremiumHighlight.assistants ||
    PremiumHighlight.household => null,
  };
}
