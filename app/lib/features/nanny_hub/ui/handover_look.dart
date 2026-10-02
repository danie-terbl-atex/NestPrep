import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../model/handover_kind.dart';
import '../model/handover_mood.dart';

/// How each kind of handover entry is drawn, in one place so shift mode's
/// buttons, the log and a summary agree. The icon and the name carry it as
/// well as the tint (`FE-13`).
extension HandoverLook on HandoverKind {
  IconData get icon => switch (this) {
    HandoverKind.meal => LucideIcons.utensils,
    HandoverKind.nap => LucideIcons.moon,
    HandoverKind.nappy => LucideIcons.baby,
    HandoverKind.mood => LucideIcons.smile,
    HandoverKind.incident => LucideIcons.bandage,
    HandoverKind.medicine => LucideIcons.pill,
    HandoverKind.note => LucideIcons.notebookPen,
  };

  NestTileTint get tint => switch (this) {
    HandoverKind.meal => NestTileTint.butter,
    HandoverKind.nap => NestTileTint.lilac,
    HandoverKind.nappy => NestTileTint.basil,
    HandoverKind.mood => NestTileTint.accent,
    HandoverKind.incident => NestTileTint.guava,
    HandoverKind.medicine => NestTileTint.guava,
    HandoverKind.note => NestTileTint.accent,
  };
}

extension MoodLook on HandoverMood {
  IconData get icon => switch (this) {
    HandoverMood.happy => LucideIcons.laugh,
    HandoverMood.calm => LucideIcons.smile,
    HandoverMood.tired => LucideIcons.moon,
    HandoverMood.upset => LucideIcons.frown,
    HandoverMood.unwell => LucideIcons.thermometer,
  };
}
