import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/money/money.dart';

part 'product_match.freezed.dart';

/// The shops a product match can be at. Only Checkers Sixty60 is connected
/// today; Pick n Pay and Woolworths are named so the shop picker can show
/// them as coming, and the field is stored so connecting one is additive
/// (`BE-10`). Each needs its own ADR before it is connected (ADR-0001).
enum ProductRetailer {
  checkers('checkers', isConnected: true),
  pickNPay('pickNPay', isConnected: false),
  woolworths('woolworths', isConnected: false);

  const ProductRetailer(this.code, {required this.isConnected});

  /// As stored in `productMatch.retailer`.
  final String code;

  /// Whether NestPrep can search this shop yet. Only a connected shop can be
  /// chosen, so a lookup never goes to a shop that cannot answer.
  final bool isConnected;

  static ProductRetailer? fromCode(String code) =>
      values.where((retailer) => retailer.code == code).firstOrNull;
}

/// The product a member picked for a grocery item, as it was when they picked
/// it — the `productMatch` field of
/// `households/{id}/groceryItems/{itemId}` (the Checkers build contract).
///
/// It is a *pick*, not a price promise: the Function that adds it to a cart
/// re-reads the product and its price from Checkers itself. Renaming the item
/// clears it, because the pick belonged to the old name.
@freezed
abstract class ProductMatch with _$ProductMatch {
  const factory ProductMatch({
    required ProductRetailer retailer,

    /// The Sixty60 product id, the same id a cart line carries.
    required String productId,

    /// Article number and unit of measure together, e.g. `10136729EA` — the
    /// backup key when a product id is ever re-issued.
    required String articleCode,

    /// `EA`, `KG`, `PK1`… as Checkers sends it. `KG` is sold by weight.
    required String unitOfMeasure,
    required String name,
    String? brand,

    /// What it cost when it was picked (`ENG-20`); per kilogram for a
    /// weighed item.
    required Money price,
    String? imageId,

    /// The member profile that picked it, the same convention as `addedBy`.
    required String pickedBy,

    /// Null while the write has not reached the server.
    DateTime? pickedAt,
  }) = _ProductMatch;

  const ProductMatch._();

  bool get isSoldByWeight => unitOfMeasure == 'KG';
}
