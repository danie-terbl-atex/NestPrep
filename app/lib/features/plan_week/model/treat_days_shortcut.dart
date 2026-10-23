import 'package:flutter/foundation.dart';

import 'treat_days.dart';

/// The one-tap answers to "which days get a treat" in *Plan my week*'s
/// brief (lunch-box ADR-0025). A shortcut is lit when the chosen days are
/// exactly its days, so fine-tuning a day turns it off.
enum TreatDaysShortcut {
  none(<int>{}),
  fridaysOnly(TreatDays.fridayOnly),
  everyDay({...TreatDays.schoolDays});

  const TreatDaysShortcut(this.days);

  final Set<int> days;

  bool isChosenFor(Set<int> treatDays) => setEquals(days, treatDays);
}
