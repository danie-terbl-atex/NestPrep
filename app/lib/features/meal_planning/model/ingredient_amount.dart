/// Reads the amount somebody typed for an ingredient (meal-planning ADR-0002):
/// `2`, `1.5`, `1,5`, `½`, `1/2` or `1 1/2`. Returns null for an empty field,
/// and throws `FormatException` for anything else — the form shows that on the
/// field rather than silently dropping what was typed (`FE-10`).
///
/// A parsed amount is always positive and below [ingredientAmountLimit]; nobody buys a
/// hundred thousand of anything, and a typo that says so should be caught.
double? parseIngredientAmount(String typed) {
  final text = typed.trim().replaceAll(',', '.');
  if (text.isEmpty) return null;
  final value = _mixed(text) ?? _fraction(text) ?? double.tryParse(text);
  if (value == null ||
      value.isNaN ||
      value <= 0 ||
      value >= ingredientAmountLimit) {
    throw FormatException('not an amount', typed);
  }
  return value;
}

/// Above anything a household would buy for one meal.
const ingredientAmountLimit = 100000.0;

const _vulgarFractions = {'½': 0.5, '¼': 0.25, '¾': 0.75, '⅓': 1 / 3};

double? _fraction(String text) {
  final vulgar = _vulgarFractions[text];
  if (vulgar != null) return vulgar;
  final parts = text.split('/');
  if (parts.length != 2) return null;
  final top = double.tryParse(parts[0].trim());
  final bottom = double.tryParse(parts[1].trim());
  if (top == null || bottom == null || bottom == 0) return null;
  return top / bottom;
}

/// `1 1/2` and `1½`.
double? _mixed(String text) {
  final match = RegExp(r'^(\d+)\s*(\S+)$').firstMatch(text);
  if (match == null) return null;
  final fraction = _fraction(match.group(2)!);
  if (fraction == null || fraction >= 1) return null;
  return int.parse(match.group(1)!) + fraction;
}
