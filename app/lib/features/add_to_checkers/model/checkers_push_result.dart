import 'package:flutter/foundation.dart';

import '../../../shared/money/money.dart';

/// Why the server left an item out of the cart.
enum CheckersSkipReason {
  noMatch('no-match'),
  outOfStock('out-of-stock'),
  notFound('not-found'),
  weighedItem('weighed-item'),

  /// A reason this build does not know: a Function deployed after it.
  unrecognised('');

  const CheckersSkipReason(this.code);

  final String code;

  static CheckersSkipReason fromCode(String code) =>
      values.where((reason) => reason.code == code).firstOrNull ?? unrecognised;
}

@immutable
final class CheckersAddedLine {
  const CheckersAddedLine({
    required this.itemId,
    required this.productId,
    required this.name,
    required this.price,
  });

  final String itemId;
  final String productId;
  final String name;
  final Money price;
}

@immutable
final class CheckersSkippedLine {
  const CheckersSkippedLine({required this.itemId, required this.reason});

  final String itemId;
  final CheckersSkipReason reason;
}

/// What `checkersPushToCart` did: what went into the member's cart, what did
/// not and why, and the cart as Checkers counts it afterwards.
@immutable
final class CheckersPushResult {
  const CheckersPushResult({
    required this.added,
    required this.skipped,
    required this.cartItemCount,
    required this.cartTotal,
  });

  final List<CheckersAddedLine> added;
  final List<CheckersSkippedLine> skipped;
  final int cartItemCount;
  final Money cartTotal;

  bool get addedNothing => added.isEmpty;
}
