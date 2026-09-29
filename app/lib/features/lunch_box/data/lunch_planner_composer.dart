import 'dart:typed_data';

import '../model/lunch_card_content.dart';

/// Makes the printable A4 lunch planner (lunch-box ADR-0005): blank — the
/// free printable — when [content] is null, or the week's plan with a page
/// per child. Behind an interface so the share screen's tests need no fonts.
abstract interface class LunchPlannerComposer {
  Future<Uint8List> compose({
    required LunchCardContent? content,
    required bool showsInvite,
    required String? inviteHost,
  });
}
