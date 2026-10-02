import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../model/routine/routine_cadence.dart';

/// How a cadence looks: its icon and its tile's tint. Never the only signal
/// — its name is always beside it (`FE-13`).
extension RoutineCadenceLook on RoutineCadence {
  IconData get icon => switch (this) {
    RoutineCadence.daily => LucideIcons.calendarCheck,
    RoutineCadence.weekly => LucideIcons.calendarRange,
    RoutineCadence.deepClean => LucideIcons.sparkles,
  };

  NestTileTint get tint => switch (this) {
    RoutineCadence.daily => NestTileTint.basil,
    RoutineCadence.weekly => NestTileTint.lilac,
    RoutineCadence.deepClean => NestTileTint.butter,
  };
}
