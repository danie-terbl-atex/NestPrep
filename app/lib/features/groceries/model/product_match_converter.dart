import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../../shared/log/app_log.dart';
import '../../../shared/money/money.dart';
import 'product_match.dart';

/// Reads and writes a grocery item's `productMatch` (`ENG-09`).
///
/// A map of the wrong shape reads as *no pick* and is logged, rather than
/// throwing: one bad item must not take the whole list down with it, and the
/// member can simply pick again. The rules hold the shape on every write, so
/// this is a Function or a build of another age, not a person's typing.
class ProductMatchConverter implements JsonConverter<ProductMatch?, Object?> {
  const ProductMatchConverter();

  @override
  ProductMatch? fromJson(Object? json) {
    if (json == null) return null;
    final match = _parse(json);
    if (match == null) {
      AppLog.failure('grocery product match', code: 'unreadable');
    }
    return match;
  }

  ProductMatch? _parse(Object json) {
    if (json case {
      'retailer': final String retailerCode,
      'productId': final String productId,
      'articleCode': final String articleCode,
      'unitOfMeasure': final String unitOfMeasure,
      'name': final String name,
      'priceCents': final int priceCents,
      'currency': final String currencyCode,
      'pickedBy': final String pickedBy,
    }) {
      final retailer = ProductRetailer.fromCode(retailerCode);
      final currency = Currency.fromCode(currencyCode);
      if (retailer == null || currency == null) return null;
      return ProductMatch(
        retailer: retailer,
        productId: productId,
        articleCode: articleCode,
        unitOfMeasure: unitOfMeasure,
        name: name,
        brand: switch (json['brand']) {
          final String brand when brand.isNotEmpty => brand,
          _ => null,
        },
        price: Money(priceCents, currency: currency),
        imageId: switch (json['imageId']) {
          final String imageId when imageId.isNotEmpty => imageId,
          _ => null,
        },
        pickedBy: pickedBy,
        pickedAt: switch (json['pickedAt']) {
          final Timestamp at => at.toDate().toUtc(),
          _ => null,
        },
      );
    }
    return null;
  }

  @override
  Object? toJson(ProductMatch? match) => match == null
      ? null
      : {
          'retailer': match.retailer.code,
          'productId': match.productId,
          'articleCode': match.articleCode,
          'unitOfMeasure': match.unitOfMeasure,
          'name': match.name,
          'brand': match.brand,
          'priceCents': match.price.cents,
          'currency': match.price.currency.code,
          'imageId': match.imageId,
          'pickedBy': match.pickedBy,
          'pickedAt': switch (match.pickedAt) {
            final DateTime at => Timestamp.fromDate(at.toUtc()),
            null => FieldValue.serverTimestamp(),
          },
        };
}
