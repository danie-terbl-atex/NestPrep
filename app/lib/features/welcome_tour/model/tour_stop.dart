import 'package:flutter/foundation.dart';

import 'tour_place.dart';
import 'tour_premium.dart';
import 'tour_target.dart';

/// One callout of the welcome tour as one person will see it
/// (welcome-tour ADR-0002): where it happens, what it spotlights, what to
/// spotlight instead if that is not on the screen, and how it is worded.
@immutable
class TourStop {
  const TourStop(
    this.target, {
    required this.place,
    this.fallbacks = const [],
    this.premium = TourPremium.none,
    this.isLookOnly = false,
  });

  final TourTarget target;
  final TourPlace place;

  /// Tried in order when [target] is not on the screen — a child switcher
  /// with only one child, a board with no children. None found: the stop is
  /// skipped, never pointed at nothing.
  final List<TourTarget> fallbacks;

  /// Whether this is premium's, and whether the household has it.
  final TourPremium premium;

  /// It speaks to somebody who can see this but not change it.
  final bool isLookOnly;

  /// Everything this stop may spotlight, best first.
  List<TourTarget> get candidates => [target, ...fallbacks];

  @override
  bool operator ==(Object other) =>
      other is TourStop &&
      other.target == target &&
      other.place == place &&
      listEquals(other.fallbacks, fallbacks) &&
      other.premium == premium &&
      other.isLookOnly == isLookOnly;

  @override
  int get hashCode => Object.hash(
    target,
    place,
    Object.hashAll(fallbacks),
    premium,
    isLookOnly,
  );

  @override
  String toString() =>
      'TourStop($target @ ${place.name}'
      '${premium == TourPremium.none ? '' : ', ${premium.name}'}${isLookOnly ? ', look' : ''})';
}
