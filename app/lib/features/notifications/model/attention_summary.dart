import 'package:flutter/foundation.dart';

import 'inbox_item.dart';
import 'notification_vocabulary.dart';

/// What in a person's inbox still waits on them: every unread notification
/// except the morning digest, which the first-open banner already offers
/// (notifications ADR-0005), and the test push they sent themselves.
/// Kinds are in the order the vocabulary lists them, so the words never
/// reshuffle as counts change.
@immutable
final class AttentionSummary {
  const AttentionSummary._(this.byKind);

  factory AttentionSummary.of(List<InboxItem> items) {
    final counts = <NotificationCategory, int>{};
    for (final item in items) {
      if (!item.isUnread || _ignored.contains(item.category)) continue;
      counts.update(item.kind, (count) => count + 1, ifAbsent: () => 1);
    }
    return AttentionSummary._({
      for (final kind in NotificationCategory.values) kind: ?counts[kind],
    });
  }

  // By the stored name, so a kind this build cannot read still counts (it
  // reads as `digest`, worded as a plain notification).
  static final _ignored = {
    NotificationCategory.digest.name,
    NotificationCategory.test.name,
  };

  final Map<NotificationCategory, int> byKind;

  int get total => byKind.values.fold(0, (sum, count) => sum + count);

  bool get isEmpty => byKind.isEmpty;
}
