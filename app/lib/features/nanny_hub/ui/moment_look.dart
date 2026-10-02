import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../model/shift_moment.dart';

/// How each part of a shift is drawn, in one place so the checklists screen
/// and shift mode agree. The name is always beside it (`FE-13`).
extension MomentLook on ShiftMoment {
  IconData get icon => switch (this) {
    ShiftMoment.arrival => Icons.door_front_door_outlined,
    ShiftMoment.afterSchool => Icons.backpack_outlined,
    ShiftMoment.dinner => Icons.dinner_dining_outlined,
    ShiftMoment.bedtime => Icons.bathtub_outlined,
    ShiftMoment.beforeLeaving => Icons.waving_hand_outlined,
  };

  NestTileTint get tint => switch (this) {
    ShiftMoment.arrival => NestTileTint.basil,
    ShiftMoment.afterSchool => NestTileTint.lilac,
    ShiftMoment.dinner => NestTileTint.butter,
    ShiftMoment.bedtime => NestTileTint.accent,
    ShiftMoment.beforeLeaving => NestTileTint.guava,
  };
}
