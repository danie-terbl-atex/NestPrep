import 'package:flutter/foundation.dart';

import 'photo_update.dart';
import 'shift.dart';

/// One shift and the photos sent from it, newest first — what the parents'
/// feed and shift mode's "sent so far" render (nanny-hub ADR-0004).
@immutable
class PhotoFeed {
  PhotoFeed({required this.shift, required List<PhotoUpdate> updates})
    : updates = List.unmodifiable(updates);

  /// Null once the shift is gone, or was never there.
  final Shift? shift;
  final List<PhotoUpdate> updates;

  bool get isGone => shift == null;

  /// Photos still arrive: the shift has not ended.
  bool get isLive => shift?.isOpen ?? false;
}
