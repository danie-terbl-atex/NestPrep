import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../model/shift_moment.dart';

/// How each part of a shift is drawn, in one place so the checklists screen
/// and shift mode agree. The name is always beside it (`FE-13`).
extension MomentLook on ShiftMoment {
  IconData get icon => switch (this) {
    ShiftMoment.arrival => LucideIcons.doorClosed,
    ShiftMoment.afterSchool => LucideIcons.backpack,
    ShiftMoment.dinner => LucideIcons.utensils,
    ShiftMoment.bedtime => LucideIcons.bath,
    ShiftMoment.beforeLeaving => LucideIcons.hand,
  };

  NestTileTint get tint => switch (this) {
    ShiftMoment.arrival => NestTileTint.basil,
    ShiftMoment.afterSchool => NestTileTint.lilac,
    ShiftMoment.dinner => NestTileTint.butter,
    ShiftMoment.bedtime => NestTileTint.accent,
    ShiftMoment.beforeLeaving => NestTileTint.guava,
  };
}
