import 'package:flutter/foundation.dart';

import '../../../shared/time/calendar_date.dart';

/// How near a document is to expiring, in the order that matters to a person.
enum ExpiryUrgency {
  /// No expiry date at all.
  none,

  /// Further off than the first reminder.
  later,

  /// Inside the first reminder's window (90 days).
  comingUp,

  /// Inside the second (30 days) — the "expiring soon" everybody means.
  soon,

  /// Today is the last day.
  today,

  /// Already past.
  expired;

  /// Whether this belongs in "expiring soon": the documents somebody should
  /// act on now.
  bool get needsAttention => this == soon || this == today || this == expired;
}

/// One document's expiry, worked out once for the badge and the filter
/// (`FE-12`).
@immutable
class ExpiryStatus {
  const ExpiryStatus({
    required this.urgency,
    required this.daysLeft,
    required this.date,
  });

  const ExpiryStatus.none()
    : urgency = ExpiryUrgency.none,
      daysLeft = null,
      date = null;

  final ExpiryUrgency urgency;

  /// Days from today to the expiry; negative once it has passed.
  final int? daysLeft;
  final CalendarDate? date;

  bool get needsAttention => urgency.needsAttention;
}
