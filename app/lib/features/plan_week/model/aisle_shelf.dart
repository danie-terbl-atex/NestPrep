import 'package:flutter/foundation.dart';

import '../../add_to_checkers/model/checkers_shelf.dart';
import '../../lunch_box/model/lunch_slot.dart';

/// One shelf of Checkers' Kids Lunchbox aisle as NestPrep keeps it
/// (lunch-box ADR-0013): what to call it, the compartment it fills, and
/// where it is read from — Checkers' own product list, then a display
/// category when the list has nothing.
@immutable
final class AisleShelf {
  const AisleShelf({
    required this.title,
    required this.slot,
    this.list,
    this.category,
  }) : assert(
         list != null || category != null,
         'a shelf is read from somewhere',
       );

  static const titleLimit = 60;

  final String title;
  final LunchSlot slot;
  final CheckersShelf? list;
  final CheckersShelf? category;

  /// Where the shelf is read from, in turn, until one has something.
  List<CheckersShelf> get sources => [?list, ?category];

  /// One entry of `appConfig/lunchAisle`'s `shelves`, or null when it is
  /// not a shelf this build can read (`ENG-09`).
  static AisleShelf? fromFields(Object? data) {
    if (data case {
      'title': final String rawTitle,
      'slot': final String slotName,
    }) {
      final title = rawTitle.trim();
      final slot = LunchSlot.fromName(slotName);
      final list = _id(data['listId']);
      final category = _id(data['categoryId']);
      if (title.isEmpty || title.length > titleLimit || slot == null) {
        return null;
      }
      if (list == null && category == null) return null;
      return AisleShelf(
        title: title,
        slot: slot,
        list: list == null ? null : CheckersShelf.productList(list),
        category: category == null
            ? null
            : CheckersShelf.displayCategory(category),
      );
    }
    return null;
  }

  static String? _id(Object? value) => switch (value) {
    final String id when CheckersShelf.isId(id) => id,
    _ => null,
  };
}
