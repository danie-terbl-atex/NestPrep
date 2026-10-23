import '../../../shared/text/cut_text.dart';
import '../../lunch_box/model/lunch_item.dart';
import '../../lunch_box/model/lunch_slot.dart';
import 'checked_product.dart';

/// The library item a shop product becomes when a week is used (lunch-box
/// ADR-0012 §3): named after the product, cut to what the rules allow, in the
/// compartment it was found for, carrying the allergens its words name. Not
/// yet written — `id` is empty until the library has it, or the board
/// already holds one like it (`LunchBoard.itemLike`).
LunchItem shopProductItem(
  CheckedProduct product,
  LunchSlot slot, {
  required String addedBy,
}) => LunchItem.named(
  id: '',
  name: cutText(product.product.name.trim(), LunchItem.nameLimit),
  slot: slot,
  allergens: product.allergens,
  addedBy: addedBy,
);
