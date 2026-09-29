/// How much of a product is left, as a person sees it by lifting the bottle
/// (home-care ADR-0005). A product marked [low] or [out] goes onto the grocery
/// list once, by the server.
///
/// The names are stored as they are written here, and
/// `rules/firestore/household/home_care.rules` and the Function list the same
/// ones.
enum StockLevel {
  full,
  half,
  low,
  out;

  /// Whether it is on its way to the grocery list.
  bool get isRunningOut => this == low || this == out;
}
