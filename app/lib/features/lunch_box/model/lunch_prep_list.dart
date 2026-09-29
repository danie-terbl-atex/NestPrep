import 'package:flutter/foundation.dart';

import 'lunch_prep.dart';
import 'lunch_week.dart';
import 'lunch_week_items.dart';

/// One row of the Sunday prep list.
@immutable
class LunchPrepRow {
  const LunchPrepRow({required this.item, required this.isDone});

  final LunchWeekItem item;
  final bool isDone;
}

/// The Sunday prep list for one household week (lunch-box ADR-0003): what to
/// batch-prep — the items the library marks as worth making ahead — and,
/// below it, everything else the week's boxes need in the house, each with
/// how many boxes it goes in.
@immutable
class LunchPrepList {
  LunchPrepList({
    required this.week,
    required List<LunchWeekItem> items,
    required LunchPrep prep,
  }) : batch = List.unmodifiable([
         for (final item in items)
           if (item.prepAhead)
             LunchPrepRow(item: item, isDone: prep.isDone(item.itemId)),
       ]),
       onHand = List.unmodifiable([
         for (final item in items)
           if (!item.prepAhead)
             LunchPrepRow(item: item, isDone: prep.isDone(item.itemId)),
       ]);

  final LunchWeek week;

  /// Make these on Sunday.
  final List<LunchPrepRow> batch;

  /// Have these in the house.
  final List<LunchPrepRow> onHand;

  bool get isEmpty => batch.isEmpty && onHand.isEmpty;

  int get doneCount => [...batch, ...onHand].where((row) => row.isDone).length;

  int get totalCount => batch.length + onHand.length;
}
