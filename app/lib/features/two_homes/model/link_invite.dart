import 'package:flutter/foundation.dart';

import 'co_parent_home.dart';
import 'custody_schedule.dart';

/// A code this home just made for the other one (household ADR-0004).
@immutable
class LinkInviteCode {
  const LinkInviteCode({required this.code, required this.expiresAt});

  final String code;
  final DateTime expiresAt;
}

/// What a code offers, as `previewCoParentInvite` tells the accepting admin:
/// the child's first name, the other home and the schedule it proposes —
/// exactly what they are agreeing to, and nothing else about the household
/// that made it.
@immutable
class LinkInvitePreview {
  const LinkInvitePreview({
    required this.code,
    required this.childName,
    required this.home,
    required this.schedule,
  });

  final String code;
  final String childName;
  final CoParentHome home;
  final CustodySchedule schedule;
}
