import '../../add_to_checkers/model/retailer_product.dart';
import '../../lunch_box/model/lunch_slot.dart';

/// Boxes one pack of a product fills when nobody reckoned it (lunch-box
/// ADR-0028 §3): the count the shop gave, else — for a bag of fruit or veg —
/// its weight at a box's share, else one. Without the weight a week of one
/// fruit would buy a "1kg" bag a day.
abstract final class LunchPackBoxes {
  static const most = 30;
  static const _gramsPerBox = {LunchSlot.fruit: 150, LunchSlot.veg: 100};

  static int of(RetailerProduct product, LunchSlot slot) {
    if (product.packCount case final count?) return count;
    final perBox = _gramsPerBox[slot];
    final grams = perBox == null ? null : gramsIn(product.name);
    if (perBox == null || grams == null) return 1;
    return (grams ~/ perBox).clamp(1, most);
  }

  /// The weight a name states — "1kg", "1,5 kg", "500g" — in grams.
  static int? gramsIn(String name) {
    final match = _weight.firstMatch(name);
    if (match == null) return null;
    final amount = double.tryParse(match.group(1)!.replaceAll(',', '.'));
    if (amount == null) return null;
    final isKilos = match.group(2)!.toLowerCase() == 'kg';
    return (amount * (isKilos ? 1000 : 1)).round();
  }

  static final _weight = RegExp(
    r'(\d+(?:[.,]\d+)?)\s*(kg|g)\b',
    caseSensitive: false,
  );
}
