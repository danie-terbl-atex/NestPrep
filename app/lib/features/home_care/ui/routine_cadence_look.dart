import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../model/routine/routine_cadence.dart';

/// How a cadence looks: its icon and its tile's tint. Never the only signal
/// — its name is always beside it (`FE-13`).
extension RoutineCadenceLook on RoutineCadence {
  IconData get icon => switch (this) {
    RoutineCadence.daily => Icons.today_outlined,
    RoutineCadence.weekly => Icons.date_range_outlined,
    RoutineCadence.deepClean => Icons.auto_awesome_outlined,
  };

  NestTileTint get tint => switch (this) {
    RoutineCadence.daily => NestTileTint.mint,
    RoutineCadence.weekly => NestTileTint.sky,
    RoutineCadence.deepClean => NestTileTint.peach,
  };
}
