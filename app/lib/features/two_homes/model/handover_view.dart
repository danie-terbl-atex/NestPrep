import 'package:flutter/foundation.dart';

import 'co_parent_link.dart';
import 'handover_note.dart';

/// What one handover screen shows: the link, for the homes' names, and the
/// handover as both homes last saved it.
@immutable
class HandoverView {
  const HandoverView({required this.link, required this.note});

  final CoParentLink link;

  /// Null while nobody has written this handover up.
  final HandoverNote? note;
}
