import 'package:flutter/foundation.dart';

import '../../../shared/money/money.dart';

/// How a week sits against its budget, gently (lunch-box ADR-0007).
enum LunchBudgetBand {
  /// Under 90% of it.
  calm,

  /// From 90% up to all of it.
  nearly,

  /// Past it.
  over,
}

/// The week's spend read against the household's weekly budget — a meter,
/// not an alarm. All the comparisons are in whole cents; [fraction] exists
/// only to draw the bar.
@immutable
class LunchBudgetReading {
  const LunchBudgetReading({required this.spent, required this.budget});

  final Money spent;
  final Money budget;

  LunchBudgetBand get band {
    if (spent.cents > budget.cents) return LunchBudgetBand.over;
    if (spent.cents * 10 >= budget.cents * 9) return LunchBudgetBand.nearly;
    return LunchBudgetBand.calm;
  }

  /// Left to spend, or how far over when [band] is over.
  Money get difference => (budget - spent).abs();

  /// How full the bar is, 0 to 1 — for the picture only.
  double get fraction => budget.cents <= 0
      ? 1
      : (spent.cents / budget.cents).clamp(0, 1).toDouble();
}
