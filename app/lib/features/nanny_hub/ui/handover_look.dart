import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../model/handover_kind.dart';
import '../model/handover_mood.dart';

/// How each kind of handover entry is drawn, in one place so shift mode's
/// buttons, the log and a summary agree. The icon and the name carry it as
/// well as the tint (`FE-13`).
extension HandoverLook on HandoverKind {
  IconData get icon => switch (this) {
    HandoverKind.meal => Icons.restaurant_outlined,
    HandoverKind.nap => Icons.bedtime_outlined,
    HandoverKind.nappy => Icons.baby_changing_station_outlined,
    HandoverKind.mood => Icons.mood_outlined,
    HandoverKind.incident => Icons.healing_outlined,
    HandoverKind.medicine => Icons.medication_outlined,
    HandoverKind.note => Icons.edit_note_outlined,
  };

  NestTileTint get tint => switch (this) {
    HandoverKind.meal => NestTileTint.peach,
    HandoverKind.nap => NestTileTint.sky,
    HandoverKind.nappy => NestTileTint.mint,
    HandoverKind.mood => NestTileTint.accent,
    HandoverKind.incident => NestTileTint.pink,
    HandoverKind.medicine => NestTileTint.pink,
    HandoverKind.note => NestTileTint.accent,
  };
}

extension MoodLook on HandoverMood {
  IconData get icon => switch (this) {
    HandoverMood.happy => Icons.sentiment_very_satisfied_outlined,
    HandoverMood.calm => Icons.sentiment_satisfied_outlined,
    HandoverMood.tired => Icons.bedtime_outlined,
    HandoverMood.upset => Icons.sentiment_dissatisfied_outlined,
    HandoverMood.unwell => Icons.sick_outlined,
  };
}
