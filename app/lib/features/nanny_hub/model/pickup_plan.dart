import 'package:flutter/foundation.dart';

import 'pickup_collector.dart';

/// What happens at collection time for one child on one day: who comes, when
/// and where, and whether that is the usual week or a change for the date
/// (nanny-hub ADR-0005). Worked out by `NannyPickups.planFor`.
@immutable
final class PickupPlan {
  const PickupPlan({
    required this.collector,
    required this.isChange,
    this.atMinute,
    this.place,
    this.note,
  });

  final PickupCollector collector;

  /// A change for this date, rather than the weekday's usual run — marked so a
  /// carer does not hand a child to the Tuesday person on the one Tuesday it
  /// is somebody else.
  final bool isChange;
  final int? atMinute;
  final String? place;
  final String? note;

  @override
  bool operator ==(Object other) =>
      other is PickupPlan &&
      other.collector == collector &&
      other.isChange == isChange &&
      other.atMinute == atMinute &&
      other.place == place &&
      other.note == note;

  @override
  int get hashCode => Object.hash(collector, isChange, atMinute, place, note);
}
