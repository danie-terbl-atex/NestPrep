import 'package:flutter/foundation.dart';

import '../../add_to_checkers/model/retailer_shelf.dart';
import '../../lunch_box/model/lunch_slot.dart';

/// One shelf of a shop's lunchbox aisle as NestPrep keeps it: what to call
/// it, the compartment it fills, and where it is read from — at Checkers its
/// own product list, then a display category when the list has nothing
/// (lunch-box ADR-0013); at Pick n Pay one category (lunch-box ADR-0026).
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
  final RetailerShelf? list;
  final RetailerShelf? category;

  /// Where the shelf is read from, in turn, until one has something.
  List<RetailerShelf> get sources => [?list, ?category];

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
        list: list == null ? null : RetailerShelf.productList(list),
        category: category == null
            ? null
            : RetailerShelf.displayCategory(category),
      );
    }
    return null;
  }

  /// One entry of `appConfig/lunchAisle`'s `pnpShelves` —
  /// `{title, slot, categoryCode}` — or null when this build cannot read it.
  static AisleShelf? fromPnpFields(Object? data) {
    if (data case {
      'title': final String rawTitle,
      'slot': final String slotName,
      'categoryCode': final String code,
    }) {
      final title = rawTitle.trim();
      final slot = LunchSlot.fromName(slotName);
      if (title.isEmpty || title.length > titleLimit || slot == null) {
        return null;
      }
      if (!RetailerShelf.isPnpCode(code)) return null;
      return AisleShelf(
        title: title,
        slot: slot,
        category: RetailerShelf.pnpCategory(code),
      );
    }
    return null;
  }

  static String? _id(Object? value) => switch (value) {
    final String id when RetailerShelf.isId(id) => id,
    _ => null,
  };
}
