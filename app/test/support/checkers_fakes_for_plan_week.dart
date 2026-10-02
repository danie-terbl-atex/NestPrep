import 'package:nestprep/features/add_to_checkers/model/checkers_product.dart';
import 'package:nestprep/shared/money/money.dart';

/// A shop product for a *Plan my week* test: what the shop says is in it is
/// [ingredients] (null for nothing said), priced in cents.
CheckersProduct planWeekProduct(
  String name, {
  String? id,
  int cents = 2500,
  String? ingredients,
  int? packCount,
  String unit = 'EA',
  bool isInStock = true,
}) => CheckersProduct(
  id: id ?? 'p-${name.toLowerCase().replaceAll(' ', '-')}',
  storeId: 'store-1',
  articleNumber: '1000',
  unitOfMeasure: unit,
  name: name,
  price: Money(cents),
  isOnPromotion: false,
  isInStock: isInStock,
  ingredientsText: ingredients,
  packCount: packCount,
);
