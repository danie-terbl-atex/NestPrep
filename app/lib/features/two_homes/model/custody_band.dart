import 'package:flutter/foundation.dart';

import 'co_parent_home.dart';
import 'co_parent_link.dart';
import 'custody_days.dart';

/// One linked child's day on the household's calendar: which home, and
/// whether it is the day they change (household ADR-0004).
@immutable
class CustodyBand {
  const CustodyBand({required this.link, required this.day});

  final CoParentLink link;
  final CustodyDay day;

  CoParentHome get home => link.homeOf(day.side);

  /// Whether the child is with this household on the day.
  bool get isWithUs => day.side == link.ownSide;

  /// Stable across rebuilds, for the list key (`FE-11`).
  String get key => 'custody_${link.id}_${day.date.iso}';
}
