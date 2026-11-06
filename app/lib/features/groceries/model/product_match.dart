import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/money/money.dart';

part 'product_match.freezed.dart';

/// The shops a product match can be at, each behind its own switch
/// (add-to-pnp ADR-0007, add-to-woolworths ADR-0001). *Plan my week* and the
/// photo frames plan at Checkers and Pick n Pay only.
enum ProductRetailer {
  checkers('checkers', isConnected: true),
  pickNPay('pickNPay', isConnected: true),
  woolworths('woolworths', isConnected: true);

  const ProductRetailer(this.code, {required this.isConnected});

  /// As stored in `productMatch.retailer`.
  final String code;

  /// Whether NestPrep can search this shop. Only a connected shop — and only
  /// while its switch is on — can be chosen, so a lookup never goes to a shop
  /// that cannot answer.
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

    /// The shop's national product id, the same id a cart line carries:
    /// Sixty60's 24-hex id, Pick n Pay's code (`000000000000838685_EA`), or
    /// Woolworths' SKU (`20011697`).
    required String productId,

    /// Article number and unit of measure together, e.g. `10136729EA` — the
    /// backup key when a product id is ever re-issued.
    required String articleCode,

    /// `EA`, `KG`, `PK1`… as the shop sends it. `KG` (Checkers, Woolworths)
    /// and `KGM` (Pick n Pay) are sold by weight.
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

  bool get isSoldByWeight => const {'KG', 'KGM'}.contains(unitOfMeasure);
}
