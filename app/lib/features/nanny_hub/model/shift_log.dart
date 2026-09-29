import 'package:flutter/foundation.dart';

import 'handover_entry.dart';
import 'shift.dart';

/// One shift and its handover log, as shift mode renders them. [shift] is
/// null once the shift is gone, or was never there.
@immutable
class ShiftLog {
  ShiftLog({required this.shift, required List<HandoverEntry> entries})
    : entries = List.unmodifiable(entries);

  final Shift? shift;

  /// In the order they happened.
  final List<HandoverEntry> entries;

  /// Newest first, the way a log is read during the shift.
  List<HandoverEntry> get newestFirst => entries.reversed.toList();

  bool get isGone => shift == null;
}
