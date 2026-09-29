import 'lunch_suggestions.dart';

/// One reason a suggestion sits where it does — the learning made visible
/// (lunch-box ADR-0003). The screen turns each into words; which reasons
/// apply is decided here, not in a widget (`FE-04`).
sealed class LunchSuggestionReason {
  const LunchSuggestionReason();
}

final class Eaten extends LunchSuggestionReason {
  const Eaten(this.times);
  final int times;
}

final class Left extends LunchSuggestionReason {
  const Left(this.times);
  final int times;
}

final class Liked extends LunchSuggestionReason {
  const Liked();
}

final class AlreadyThisWeek extends LunchSuggestionReason {
  const AlreadyThisWeek(this.times);
  final int times;
}

abstract final class LunchSuggestionReasons {
  static List<LunchSuggestionReason> of(LunchSuggestion suggestion) => [
    if (suggestion.isLiked) const Liked(),
    if (suggestion.taste.eaten > 0) Eaten(suggestion.taste.eaten),
    if (suggestion.taste.left > 0) Left(suggestion.taste.left),
    if (suggestion.usesThisWeek > 0) AlreadyThisWeek(suggestion.usesThisWeek),
  ];
}
