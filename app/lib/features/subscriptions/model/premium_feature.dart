/// What a family reached for when premium was offered (subscriptions
/// ADR-0001) — the paywall opens on it, and a purchase that follows is
/// counted against it (product-analytics ADR-0001). The names are the
/// server's `CONVERSION_TRIGGERS`, which
/// `subscription_contract_test.dart` reads.
///
/// `aiPlanning` and `budgetMode` are V2: nothing opens the paywall on them
/// yet, and the server already has a column for each.
enum PremiumFeature {
  /// A second child profile, past the free tier's one.
  additionalChild,

  /// Lunch-box learning what each child actually eats.
  lunchLearning,

  /// Lunch-box's Sunday prep list.
  prepList,
  aiPlanning,
  budgetMode,

  /// An AI photo of each lunchbox as it is packed (lunch-box ADR-0015).
  lunchPhoto,

  /// The plan screen, opened on purpose rather than by reaching a limit.
  direct,
}
