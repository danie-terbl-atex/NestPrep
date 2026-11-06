import 'package:flutter/foundation.dart';

/// The store Woolworths fulfils a place from, and the price field its price
/// list reads: `p10`, `p30` or `p60` on a Constructor product.
@immutable
final class WoolworthsStore {
  const WoolworthsStore({required this.id, required this.priceZone});

  final String id;
  final String priceZone;

  @override
  bool operator ==(Object other) =>
      other is WoolworthsStore &&
      other.id == id &&
      other.priceZone == priceZone;

  @override
  int get hashCode => Object.hash(id, priceZone);
}

/// What is in a product, from its Woolworths detail. Both null when it says
/// nothing — the contents are unknown.
typedef WoolworthsContents = ({String? allergenText, String? ingredientsText});
