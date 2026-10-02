import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../model/reward.dart';

/// The picture each reward icon draws, and the tile tint it sits on — the one
/// place the stored name becomes something to see.
extension RewardIconGlyph on RewardIcon {
  IconData get glyph => switch (this) {
    RewardIcon.gift => LucideIcons.gift,
    RewardIcon.treat => LucideIcons.cookie,
    RewardIcon.iceCream => LucideIcons.iceCreamCone,
    RewardIcon.screenTime => LucideIcons.tablet,
    RewardIcon.movie => LucideIcons.clapperboard,
    RewardIcon.game => LucideIcons.gamepad2,
    RewardIcon.outing => LucideIcons.trees,
    RewardIcon.book => LucideIcons.bookOpen,
    RewardIcon.toy => LucideIcons.toyBrick,
    RewardIcon.lateNight => LucideIcons.moon,
  };

  NestTileTint get tint => switch (this) {
    RewardIcon.gift || RewardIcon.toy => NestTileTint.guava,
    RewardIcon.treat || RewardIcon.iceCream => NestTileTint.butter,
    RewardIcon.screenTime || RewardIcon.game => NestTileTint.accent,
    RewardIcon.movie || RewardIcon.lateNight => NestTileTint.lilac,
    RewardIcon.outing || RewardIcon.book => NestTileTint.basil,
  };
}
