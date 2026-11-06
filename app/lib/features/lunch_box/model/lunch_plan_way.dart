/// The ways *Plan the week* offers (lunch-box ADR-0033): Twig leads for a
/// Premium household and follows the free way for everyone else; a week with
/// every day packed leaves only Twig, who plans every child.
enum LunchPlanWay {
  twig,
  boxes,
  pantry;

  static List<LunchPlanWay> offered({
    required bool hasTwig,
    required bool hasPantry,
    required bool isPremium,
    required bool isFull,
  }) => [
    if (hasTwig && isPremium) twig,
    if (!isFull) boxes,
    if (hasTwig && !isPremium) twig,
    if (hasPantry && !isFull) pantry,
  ];
}
