/// Every component on a real screen the welcome tour can spotlight
/// (welcome-tour ADR-0002). A screen places one with a `TourAnchor`; the
/// tour asks for it by this id and never reaches into the screen otherwise.
///
/// `tour_anchor_contract_test.dart` reads the screens and fails if a target a
/// step can ask for is placed nowhere — a moved component is caught there,
/// not by a tour that silently skips it.
enum TourTarget {
  /// The bar's five places.
  tabBar,

  /// Today's lunchbox cards — or, with no child yet, the way to add one.
  todayLunch,

  /// The bell in the header.
  bell,

  /// The account button in the header.
  accountMenu,

  /// Who the lunch board is showing, when there is more than one child.
  lunchChildSwitcher,

  /// The week's school days as pills.
  lunchDayPills,

  /// The day's photo card.
  lunchDay,

  /// The lunch board with nobody to pack for: the way to family profiles.
  lunchNoChildren,

  /// *Plan the whole week* and its *Fill the week*.
  lunchPlanner,

  /// *Let Twig plan* inside the planner.
  lunchPlanMyWeek,

  /// The tools grid at the foot of the board.
  lunchTools,

  /// The Sunday prep tile.
  lunchPrep,

  /// The budget tile.
  lunchBudget,

  /// *Recipes | This week* at the top of the Meals tab (design-system
  /// ADR-0015).
  mealsViews,

  /// To do and Groceries, side by side.
  listsSwitch,

  /// *From this week's plans*, on the grocery list.
  groceryPlans,

  /// The people card on More.
  morePeople,

  /// The Family profiles tile on More.
  moreFamily,
}
