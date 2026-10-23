import '../../groceries/model/product_match.dart';
import 'retailer_product.dart';

/// [product] as a grocery item's match, picked by the member profile
/// [pickedBy] — at whichever shop it is from (groceries ADR-0005, ADR-0007).
/// The one place a shop product becomes a stored pick: the grocery list's
/// matches and *Plan my week*'s list lines both come through here.
ProductMatch productMatchFrom(
  RetailerProduct product, {
  required String pickedBy,
}) => ProductMatch(
  retailer: product.retailer,
  productId: product.id,
  articleCode: product.articleCode,
  unitOfMeasure: product.unitOfMeasure,
  name: product.name,
  brand: product.brand,
  price: product.price,
  imageId: product.imageId,
  pickedBy: pickedBy,
);
