import 'package:flutter/foundation.dart';

import 'grocery_proposal.dart';

/// A proposal as a person reads it and as the list would store it: the
/// quantity written out and the reasons as one sentence (groceries ADR-0002,
/// ADR-0003). Worded once, by the controller, so the sheet and the stored item
/// can never say two different things.
@immutable
class GroceryPlanLine {
  const GroceryPlanLine({
    required this.proposal,
    required this.quantity,
    required this.note,
  });

  final GroceryProposal proposal;

  /// *2 loaves*, *1.5 kg + 1 pack*; null when nothing says how much.
  final String? quantity;

  /// *For 5 lunches + Tuesday dinner*; never longer than [noteLimit].
  final String note;

  /// What the rules accept as `sourceNote`.
  static const noteLimit = 200;

  String get key => proposal.key;
  String get name => proposal.name;
}
