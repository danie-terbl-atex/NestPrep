import 'package:flutter/foundation.dart';

import '../../../shared/time/household_clock.dart';
import 'avatar_creation.dart';

@immutable
final class CreationAllowance {
  const CreationAllowance({this.left, this.hasAsked = false});

  factory CreationAllowance.from(
    List<AvatarCreation> newestFirst, {
    required HouseholdClock clock,
    required bool isPremium,
  }) {
    final today = clock.today;
    for (final creation in newestFirst) {
      final left = creation.left;
      if (left == null) continue;
      final asked = switch (creation.requestedAt) {
        final at? => clock.dateOf(at),
        null => null,
      };
      final thisMonth =
          asked?.year == today.year && asked?.month == today.month;
      if (isPremium && !thisMonth) {
        return const CreationAllowance(hasAsked: true);
      }
      return CreationAllowance(
        left: thisMonth && creation.reason == CreationRefusal.limitReached
            ? 0
            : left,
        hasAsked: true,
      );
    }
    return CreationAllowance(hasAsked: newestFirst.isNotEmpty);
  }

  final int? left;
  final bool hasAsked;

  bool freeTryUnused({required bool isPremium}) =>
      !isPremium && (left == null ? !hasAsked : left! > 0);

  bool freeTryUsed({required bool isPremium}) => !isPremium && left == 0;
}
