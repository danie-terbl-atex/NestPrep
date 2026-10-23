import '../../../shared/text/normalised_name.dart';
import '../../add_to_checkers/model/product_match_from.dart';
import '../../add_to_checkers/model/retailer_product.dart';
import '../../groceries/data/grocery_repository.dart';
import '../../groceries/model/product_match.dart';
import '../model/shop_list_entry.dart';

/// One product to put on the grocery list, what to call it, and how much of
/// it to buy — in words, or none, and in packs. A dish's ingredient is
/// called by the ingredient (groceries ADR-0006), matched to the product it
/// was bought as.
typedef ShopListLine = ({
  RetailerProduct product,
  String name,
  String? quantity,
  int packs,
});

/// Where a used week sends what it needs (lunch-box ADR-0012 §1.5): the
/// household's one grocery list, each line already matched to its product at
/// the shop the week was planned at (groceries ADR-0007) — so a cart push
/// works without anybody picking. A product already on the list and not yet
/// bought is added once, never twice.
final class ShopWeekGroceries {
  const ShopWeekGroceries({
    required GroceryRepository groceryRepository,
    required this.householdId,
    required this.memberId,
  }) : _groceries = groceryRepository;

  final GroceryRepository _groceries;
  final String householdId;
  final String memberId;

  /// Adds [lines]; answers every line as it now stands on the list — the
  /// ones added, and the ones that were there already — for a cart push.
  ///
  /// A line already on the list keeps its item, but carries **this week's**
  /// product: a pick at another shop, of another product, or none, is
  /// replaced, because only this week's product was checked against the
  /// children's rules and is what the push should buy. A new line is added
  /// with its pick in one write.
  Future<List<ShopListEntry>> add(List<ShopListLine> lines) async {
    final list = await _groceries.watchItems(householdId).first;
    final itemIds = {
      for (final item in list)
        if (!item.isBought) normalisedName(item.name): item.id,
    };
    final picks = {
      for (final item in list)
        if (!item.isBought) item.id: _matchKey(item.productMatch),
    };
    final entries = <ShopListEntry>[];
    for (final (:product, :name, :quantity, :packs) in lines) {
      final key = normalisedName(name);
      final existing = itemIds[key];
      final wanted = _productKey(product);
      if (existing == null) {
        final itemId = await _groceries.addMatched(
          householdId: householdId,
          name: name,
          quantity: quantity,
          addedBy: memberId,
          match: _matchOf(product),
        );
        itemIds[key] = itemId;
        picks[itemId] = wanted;
        entries.add(
          ShopListEntry(itemId: itemId, name: name, packs: packs, isNew: true),
        );
        continue;
      }
      if (picks[existing] != wanted) {
        await _groceries.setProductMatch(
          householdId: householdId,
          itemId: existing,
          match: _matchOf(product),
        );
        picks[existing] = wanted;
      }
      entries.add(
        ShopListEntry(itemId: existing, name: name, packs: packs, isNew: false),
      );
    }
    return entries;
  }

  /// Every unbought item on the list matched at [shop], as entries for a
  /// cart push (lunch-box ADR-0027): what is waiting to be bought there.
  /// [packsOf] reads a pack count back from the item's quantity words.
  Future<List<ShopListEntry>> waitingAt(
    ProductRetailer shop,
    int Function(String? quantity) packsOf,
  ) async {
    final list = await _groceries.watchItems(householdId).first;
    return [
      for (final item in list)
        if (!item.isBought && item.productMatch?.retailer == shop)
          ShopListEntry(
            itemId: item.id,
            name: item.name,
            packs: packsOf(item.quantity),
            isNew: false,
          ),
    ];
  }

  static String _productKey(RetailerProduct product) =>
      '${product.retailer.code}|${product.id}';

  static String? _matchKey(ProductMatch? match) =>
      match == null ? null : '${match.retailer.code}|${match.productId}';

  ProductMatch _matchOf(RetailerProduct product) =>
      productMatchFrom(product, pickedBy: memberId);
}
