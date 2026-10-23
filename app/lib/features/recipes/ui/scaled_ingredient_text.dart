import 'package:flutter/foundation.dart';

import '../../../shared/copy/app_copy.dart';
import '../model/scaled_ingredients.dart';

/// A scaled ingredient in words: its [amount] ("1 1/2 cups", "250 g", "3", or
/// nothing) and the rest of the [line] ("cake flour, sifted"; "Salt — to
/// taste"). Worked out from the line each time it is drawn — a handful of
/// string joins — so the row and its screen-reader label say the same thing.
@immutable
final class ScaledIngredientText {
  const ScaledIngredientText._({required this.amount, required this.line});

  factory ScaledIngredientText.of(ScaledIngredient ingredient) {
    final source = ingredient.line;
    final amount = ingredient.amount;
    if (amount == null) {
      return ScaledIngredientText._(
        amount: '',
        line: RecipeCopy.unmeasured(source.name, source.note),
      );
    }
    final unit = amount.unit;
    final word = unit == null
        ? ingredient.otherUnit
        : RecipeCopy.unit(unit, amount.value);
    final note = source.note;
    return ScaledIngredientText._(
      amount: [amount.number, ?word].join(' '),
      line: note == null ? source.name : RecipeCopy.noted(source.name, note),
    );
  }

  final String amount;
  final String line;
}
