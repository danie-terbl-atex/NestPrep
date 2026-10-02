import 'package:flutter/foundation.dart';

import '../../../shared/money/money.dart';

/// One product in the Checkers Sixty60 catalogue, as a search found it at one
/// store — parsed at the edge by `CheckersCatalogueParser` (`ENG-09`).
@immutable
final class CheckersProduct {
  const CheckersProduct({
    required this.id,
    required this.storeId,
    required this.articleNumber,
    required this.unitOfMeasure,
    required this.name,
    required this.price,
    required this.isOnPromotion,
    required this.isInStock,
    this.brand,
    this.oldPrice,
    this.imageId,
    this.allergenText,
    this.ingredientsText,
    this.packCount,
  });

  /// The national product id, the same id a cart line carries.
  final String id;
  final String storeId;
  final String articleNumber;

  /// `EA`, `KG`, `PK1`… — `KG` is priced and sold per kilogram.
  final String unitOfMeasure;
  final String name;
  final String? brand;

  /// Today's price at [storeId]; per kilogram when [isSoldByWeight].
  final Money price;

  /// The price before a promotion, only when it is higher than [price].
  final Money? oldPrice;

  /// On a Sixty60 promotion — a lower price, or a deal such as a bonus buy.
  final bool isOnPromotion;
  final bool isInStock;
  final String? imageId;

  /// The shop's own *Allergens* line ("Contains: Peanuts, Soya."), plain
  /// text; null when the product carries none — and many do not.
  final String? allergenText;

  /// The shop's *Ingredients* line, plain text; null when it carries none.
  final String? ingredientsText;

  /// How many units one pack holds when the shop says so plainly
  /// ("6 x 100g", a pack quantity above one); null when it cannot be told.
  final int? packCount;

  bool get isSoldByWeight => unitOfMeasure == 'KG';

  /// Whether the shop said anything about what is in it — without either
  /// line, its allergens are unknown (lunch-box ADR-0012).
  bool get hasContentsText => allergenText != null || ingredientsText != null;

  /// The article number and unit together, e.g. `10136729EA`.
  String get articleCode => '$articleNumber$unitOfMeasure';

  @override
  bool operator ==(Object other) =>
      other is CheckersProduct && other.id == id && other.storeId == storeId;

  @override
  int get hashCode => Object.hash(id, storeId);
}
