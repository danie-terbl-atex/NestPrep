import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../model/reward.dart';

/// The picture each reward icon draws, and the tile tint it sits on — the one
/// place the stored name becomes something to see.
extension RewardIconGlyph on RewardIcon {
  IconData get glyph => switch (this) {
    RewardIcon.gift => Icons.card_giftcard_rounded,
    RewardIcon.treat => Icons.cookie_rounded,
    RewardIcon.iceCream => Icons.icecream_rounded,
    RewardIcon.screenTime => Icons.tablet_android_rounded,
    RewardIcon.movie => Icons.movie_rounded,
    RewardIcon.game => Icons.sports_esports_rounded,
    RewardIcon.outing => Icons.park_rounded,
    RewardIcon.book => Icons.menu_book_rounded,
    RewardIcon.toy => Icons.toys_rounded,
    RewardIcon.lateNight => Icons.bedtime_rounded,
  };

  NestTileTint get tint => switch (this) {
    RewardIcon.gift || RewardIcon.toy => NestTileTint.pink,
    RewardIcon.treat || RewardIcon.iceCream => NestTileTint.peach,
    RewardIcon.screenTime || RewardIcon.game => NestTileTint.accent,
    RewardIcon.movie || RewardIcon.lateNight => NestTileTint.sky,
    RewardIcon.outing || RewardIcon.book => NestTileTint.mint,
  };
}
