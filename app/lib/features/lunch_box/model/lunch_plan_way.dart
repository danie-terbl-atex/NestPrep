/// The ways *Plan the week* offers (lunch-box ADR-0033): Twig leads; a week
/// with every day packed leaves only Twig, who plans every child.
enum LunchPlanWay {
  twig,
  boxes,
  pantry;

  static List<LunchPlanWay> offered({
    required bool hasTwig,
    required bool hasPantry,
    required bool isFull,
  }) => [
    if (hasTwig) twig,
    if (!isFull) boxes,
    if (hasPantry && !isFull) pantry,
  ];
}
