import 'package:nestprep/features/add_to_checkers/model/retailer_product.dart';
import 'package:nestprep/features/groceries/model/product_match.dart';
import 'package:nestprep/shared/money/money.dart';

/// A shop product for a *Plan my week* test: what the shop says is in it is
/// [ingredients] (null for nothing said), priced in cents.
RetailerProduct planWeekProduct(
  String name, {
  String? id,
  int cents = 2500,
  String? ingredients,
  int? packCount,
  String unit = 'EA',
  bool isInStock = true,
}) => RetailerProduct(
  retailer: ProductRetailer.checkers,
  id: id ?? 'p-${name.toLowerCase().replaceAll(' ', '-')}',
  storeId: 'store-1',
  articleCode: '1000$unit',
  unitOfMeasure: unit,
  isSoldByWeight: unit == 'KG',
  name: name,
  price: Money(cents),
  isOnPromotion: false,
  isInStock: isInStock,
  ingredientsText: ingredients,
  packCount: packCount,
);
