import '../../../shared/copy/plan_week_copy.dart';
import 'shop_list_entry.dart';

/// How many packs a grocery item's quantity words ask for, when they are the
/// words *Plan my week* writes (*3 packs*); anything else — retyped, or none —
/// is one (lunch-box ADR-0027, add-to-pnp ADR-0007). Read back for a cart
/// push from the brief and from the grocery list alike.
int packsInQuantity(String? quantity) {
  final words = quantity?.trim();
  for (var packs = 1; packs <= ShopListEntry.maxPacks; packs++) {
    if (PlanWeekCopy.packs(packs) == words) return packs;
  }
  return 1;
}
