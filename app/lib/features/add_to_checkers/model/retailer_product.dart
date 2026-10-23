import 'package:flutter/foundation.dart';

import '../../../shared/money/money.dart';
import '../../groceries/model/product_match.dart';

/// One product in a shop's catalogue, as a search or a shelf found it at one
/// store — parsed at the edge by that shop's parser (`ENG-09`): Checkers'
/// `CheckersCatalogueParser`, Pick n Pay's `PnpCatalogueParser`.
@immutable
final class RetailerProduct {
  const RetailerProduct({
    required this.retailer,
    required this.id,
    required this.storeId,
    required this.articleCode,
    required this.unitOfMeasure,
    required this.name,
    required this.price,
    required this.isOnPromotion,
    required this.isInStock,
    required this.isSoldByWeight,
    this.brand,
    this.oldPrice,
    this.imageId,
    this.allergenText,
    this.ingredientsText,
    this.packCount,
  });

  final ProductRetailer retailer;

  /// The national product id, the same id a cart line carries.
  final String id;
  final String storeId;

  /// The shop's backup key for the product: Checkers' article number and
  /// unit together (`10136729EA`), Pick n Pay's code digits.
  final String articleCode;

  /// The shop's own unit code — `EA`, `KG`, `PK1` at Checkers; `EA`, `KGM`,
  /// `CK` at Pick n Pay.
  final String unitOfMeasure;
  final String name;
  final String? brand;

  /// Today's price at [storeId]; per kilogram when [isSoldByWeight].
  final Money price;

  /// The price before a promotion, only when it is higher than [price].
  final Money? oldPrice;

  /// On a promotion — a lower price, or a deal such as a bonus buy.
  final bool isOnPromotion;
  final bool isInStock;

  /// Sold by weight: its cart line needs a weight the member chooses, so it
  /// is never put in a week or a cart (lunch-box ADR-0012, add-to-pnp
  /// ADR-0002). The parser decides, by the shop's own words for it.
  final bool isSoldByWeight;

  /// The shop's reference to the picture — see `retailerImageUrl`.
  final String? imageId;

  /// The shop's own *Allergens* line ("Contains: Peanuts, Soya."), plain
  /// text; null when the product carries none — and many do not.
  final String? allergenText;

  /// The shop's *Ingredients* line, plain text; null when it carries none.
  final String? ingredientsText;

  /// How many units one pack holds when the shop says so plainly
  /// ("6 x 100g", a pack quantity above one); null when it cannot be told.
  final int? packCount;

  /// Whether the shop said anything about what is in it — without either
  /// line, its allergens are unknown (lunch-box ADR-0012).
  bool get hasContentsText => allergenText != null || ingredientsText != null;

  @override
  bool operator ==(Object other) =>
      other is RetailerProduct &&
      other.retailer == retailer &&
      other.id == id &&
      other.storeId == storeId;

  @override
  int get hashCode => Object.hash(retailer, id, storeId);
}
