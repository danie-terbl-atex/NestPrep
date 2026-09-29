import 'lunch_favourite.dart';
import 'lunch_suggestions.dart';

/// A preference auto-fill can be given (lunch-box ADR-0006): which go-to
/// boxes it may pack, and which of a slot's ranked suggestions it takes.
///
/// It chooses only among what `LunchSuggestions` already put in `suggested`
/// — safe and not disliked — so no preference can put an unsafe or a
/// disliked item in a box (lunch-box ADR-0001, ADR-0003). [added] is what
/// this fill has packed so far, by item id.
abstract interface class LunchFillBias {
  bool acceptsFavourite(LunchFavourite favourite, Map<String, int> added);

  LunchSuggestion? choose(RankedLunchItems ranked, Map<String, int> added);
}
