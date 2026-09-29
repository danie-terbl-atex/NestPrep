/// What an amount is measured in, and so what it may be added to
/// (groceries ADR-0003).
enum UnitDimension {
  /// Grams, with kilograms as a larger step of the same thing.
  mass,

  /// Millilitres, with litres as a larger step.
  volume,

  /// A plain number of things — three onions.
  count,

  /// A thing a shop sells whole. Each of these is its own dimension: two tins
  /// and a pack never add up to anything.
  pack,
  tin,
  loaf,
  bunch,
  bottle,

  /// Teaspoons and cups: how a recipe measures, not how a shop sells. They add
  /// a reason to a grocery line and never an amount.
  kitchen,
}

/// The units an ingredient may be measured in (meal-planning ADR-0002). Stored
/// by [code]; a code this build does not know reads as no unit (`BE-10`).
enum IngredientUnit {
  gram('g', UnitDimension.mass, 1),
  kilogram('kg', UnitDimension.mass, 1000),
  millilitre('ml', UnitDimension.volume, 1),
  litre('l', UnitDimension.volume, 1000),
  pack('pack', UnitDimension.pack, 1),
  tin('tin', UnitDimension.tin, 1),
  loaf('loaf', UnitDimension.loaf, 1),
  bunch('bunch', UnitDimension.bunch, 1),
  bottle('bottle', UnitDimension.bottle, 1),
  teaspoon('tsp', UnitDimension.kitchen, 1),
  tablespoon('tbsp', UnitDimension.kitchen, 3),
  cup('cup', UnitDimension.kitchen, 48);

  const IngredientUnit(this.code, this.dimension, this.inBaseUnits);

  /// As stored on a meal's ingredient, and as the rules would read it.
  final String code;
  final UnitDimension dimension;

  /// How many of the dimension's smallest unit one of these is — a kilogram
  /// is 1000 grams.
  final double inBaseUnits;

  /// Whether an amount in this unit belongs on a shopping list at all.
  bool get isShoppable => dimension != UnitDimension.kitchen;

  static IngredientUnit? fromCode(String? code) =>
      IngredientUnit.values.where((unit) => unit.code == code).firstOrNull;
}
