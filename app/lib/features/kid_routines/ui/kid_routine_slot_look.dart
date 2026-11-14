import 'package:flutter/widgets.dart';

import '../../../design/nest_kit.dart';
import '../model/kid_routine_slot.dart';

extension KidRoutineSlotLook on KidRoutineSlot {
  IconData get icon => switch (this) {
    KidRoutineSlot.morning => LucideIcons.sunrise,
    KidRoutineSlot.afternoon => LucideIcons.sun,
    KidRoutineSlot.bedtime => LucideIcons.moon,
  };
}
