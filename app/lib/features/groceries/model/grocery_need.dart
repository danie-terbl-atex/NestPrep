import 'package:flutter/foundation.dart';

import '../../../shared/text/normalised_name.dart';
import 'grocery_amount.dart';
import 'grocery_need_reason.dart';

/// One thing a source says the household needs this week (groceries
/// ADR-0004). Needs from every source are merged on [key].
@immutable
class GroceryNeed {
  const GroceryNeed({required this.name, required this.reason, this.amount});

  /// As the source spells it; the first spelling met is the one shown.
  final String name;
  final GroceryAmount? amount;
  final GroceryNeedReason reason;

  String get key => normalisedName(name);
}
