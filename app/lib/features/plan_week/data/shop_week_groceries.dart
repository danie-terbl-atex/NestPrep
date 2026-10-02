import '../../../shared/text/normalised_name.dart';
import '../../add_to_checkers/model/checkers_product.dart';
import '../../groceries/data/grocery_repository.dart';
import '../../groceries/model/product_match.dart';

/// One product to put on the grocery list, and how much of it to buy.
typedef ShopListLine = ({CheckersProduct product, String quantity});

/// Where a used week sends what it needs (lunch-box ADR-0012 §1.5): the
/// household's one grocery list, each line already matched to its Checkers
/// product — so *Add to Checkers* works without anybody picking. A product
/// already on the list and not yet bought is added once, never twice.
final class ShopWeekGroceries {
  const ShopWeekGroceries({
    required GroceryRepository groceryRepository,
    required this.householdId,
    required this.memberId,
  }) : _groceries = groceryRepository;

  final GroceryRepository _groceries;
  final String householdId;
  final String memberId;

  /// Adds [lines] and returns how many it added.
  Future<int> add(List<ShopListLine> lines) async {
    final list = await _groceries.watchItems(householdId).first;
    final onTheList = {
      for (final item in list)
        if (!item.isBought) normalisedName(item.name),
    };
    var added = 0;
    for (final (:product, :quantity) in lines) {
      if (!onTheList.add(normalisedName(product.name))) continue;
      final itemId = await _groceries.add(
        householdId: householdId,
        name: product.name,
        quantity: quantity,
        addedBy: memberId,
      );
      await _groceries.setProductMatch(
        householdId: householdId,
        itemId: itemId,
        match: ProductMatch(
          retailer: ProductRetailer.checkers,
          productId: product.id,
          articleCode: product.articleCode,
          unitOfMeasure: product.unitOfMeasure,
          name: product.name,
          brand: product.brand,
          price: product.price,
          imageId: product.imageId,
          pickedBy: memberId,
        ),
      );
      added++;
    }
    return added;
  }
}
