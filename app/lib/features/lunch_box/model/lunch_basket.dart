import 'package:flutter/foundation.dart';

import '../../../shared/money/money.dart';

/// One thing in the week's basket: how many boxes it goes in across every
/// child, how many boxes one pack does, and so how many whole packs to buy.
@immutable
final class LunchBasketLine {
  const LunchBasketLine({
    required this.key,
    required this.name,
    required this.boxes,
    required this.boxesPerPack,
    required this.packPrice,
  }) : assert(boxesPerPack > 0, 'a pack does at least one box');

  /// What the line is about — a library item's id, or a shop product's.
  final String key;
  final String name;
  final int boxes;
  final int boxesPerPack;

  /// What one pack costs at the till.
  final Money packPrice;

  /// Whole packs: the till sells no fraction of one.
  int get packs => boxes <= 0 ? 0 : (boxes + boxesPerPack - 1) ~/ boxesPerPack;

  Money get cost =>
      Money(packs * packPrice.cents, currency: packPrice.currency);
}

/// What a school week costs at the till, for the whole household together
/// (lunch-box ADR-0012 §4, amending ADR-0007 §4): each thing's boxes across
/// every child, rounded **up** to whole packs, times the pack's price. Ten
/// yoghurts from six-packs is two packs, not ten-sixths of one. Integer cents
/// throughout (`ENG-20`); nothing to round.
@immutable
final class LunchBasket {
  LunchBasket(Iterable<LunchBasketLine> lines)
    : lines = List.unmodifiable(
        <LunchBasketLine>[
          for (final line in lines)
            if (line.boxes > 0) line,
        ]..sort((a, b) => b.cost.cents.compareTo(a.cost.cents)),
      );

  static final empty = LunchBasket(const []);

  /// Dearest first.
  final List<LunchBasketLine> lines;

  Money get total =>
      lines.fold<Money>(const Money.zero(), (sum, line) => sum + line.cost);

  int get packs => lines.fold<int>(0, (sum, line) => sum + line.packs);

  bool get isEmpty => lines.isEmpty;

  LunchBasketLine? lineFor(String key) =>
      lines.where((line) => line.key == key).firstOrNull;
}
