import 'package:flutter/foundation.dart';

import 'child_in_care.dart';
import 'nanny_hub.dart';

/// What the hub's screens render: its own records and the children they are
/// about, joined with what family profiles lets the viewer read.
@immutable
class NannyHubView {
  const NannyHubView({required this.hub, required this.children});

  final NannyHub hub;
  final List<ChildInCare> children;

  ChildInCare? childById(String memberId) =>
      children.where((child) => child.memberId == memberId).firstOrNull;
}
