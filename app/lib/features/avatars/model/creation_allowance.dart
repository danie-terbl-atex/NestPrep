import 'package:flutter/foundation.dart';

import '../../../shared/time/household_clock.dart';
import 'avatar_creation.dart';

@immutable
final class CreationAllowance {
  const CreationAllowance({this.left});

  factory CreationAllowance.from(
    List<AvatarCreation> newestFirst, {
    required HouseholdClock clock,
  }) {
    final today = clock.today;
    for (final creation in newestFirst) {
      final left = creation.left;
      if (left == null || creation.reason == CreationRefusal.premiumRequired) {
        continue;
      }
      final asked = switch (creation.requestedAt) {
        final at? => clock.dateOf(at),
        null => null,
      };
      if (asked?.year != today.year || asked?.month != today.month) break;
      return CreationAllowance(
        left: creation.reason == CreationRefusal.limitReached ? 0 : left,
      );
    }
    return const CreationAllowance();
  }

  final int? left;
}
