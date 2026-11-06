import 'package:nestprep/features/add_to_checkers/model/retailer_product.dart';
import 'package:nestprep/features/groceries/model/product_match.dart';
import 'package:nestprep/shared/money/money.dart';

/// A Pick n Pay product for a test, as `PnpCatalogueParser` would read it.
RetailerProduct pnpProduct(
  String name, {
  required String code,
  int cents = 3499,
}) => RetailerProduct(
  retailer: ProductRetailer.pickNPay,
  id: code,
  storeId: 'GC13',
  articleCode: code.split('_').first,
  unitOfMeasure: code.split('_').last,
  name: name,
  price: Money(cents),
  isOnPromotion: false,
  isInStock: true,
  isSoldByWeight: false,
  ingredientsText: 'Milk',
  packCount: 6,
);
