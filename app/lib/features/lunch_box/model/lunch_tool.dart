import '../../../shared/flags/feature_flag.dart';
import '../../../shared/flags/feature_flags.dart';

/// The lunch board's ways to plan a week and the tools beside it
/// (lunch-box ADR-0022), and who is offered each — the one answer the board
/// and the welcome tour both read (welcome-tour ADR-0001), so the tour never
/// describes a tool somebody cannot open (`ENG-01`).
///
/// It only decides what is offered. Premium is asked when a premium tool is
/// opened, and the rules refuse every write regardless (`FE-04`, lunch-box
/// ADR-0009).
enum LunchTool {
  /// *Fill the week* (lunch-box ADR-0020).
  fillWeek,

  /// Planning the week from what is in the house (lunch-box ADR-0005).
  pantryPlan,

  /// *Plan my week* from what the grocer sells (lunch-box ADR-0012).
  planMyWeek,

  /// The Sunday prep list (lunch-box ADR-0009).
  prep,

  /// The household's lunch library (lunch-box ADR-0004).
  library,

  /// Cards and the printable planner (lunch-box ADR-0005).
  share,

  /// What is in the house (lunch-box ADR-0005).
  pantry,

  /// What a box and a week cost (lunch-box ADR-0006).
  budget,

  /// A child choosing from options a parent approved (lunch-box ADR-0007).
  kidPicks;

  /// The week planner's ways, in the order the board shows them.
  static const weekPlanner = [fillWeek, pantryPlan, planMyWeek];

  /// The tool grid's tiles, in the order the board shows them.
  static const grid = [prep, library, share, pantry, budget, kidPicks];

  /// Whether this is premium's — the board says so, and asks first.
  bool get isPremium => switch (this) {
    LunchTool.prep || LunchTool.budget || LunchTool.planMyWeek => true,
    _ => false,
  };

  /// Whether somebody who [canEdit] lunches — or may only look — is offered
  /// this while [flags] stand.
  bool isOpenTo({required bool canEdit, required FeatureFlags flags}) =>
      switch (this) {
        LunchTool.fillWeek || LunchTool.library || LunchTool.share => canEdit,
        LunchTool.pantryPlan => canEdit && flags.isOn(FeatureFlag.lunchPantry),
        LunchTool.planMyWeek => canEdit && flags.isOn(FeatureFlag.planMyWeek),
        LunchTool.prep => true,
        LunchTool.pantry => flags.isOn(FeatureFlag.lunchPantry),
        LunchTool.budget => flags.isOn(FeatureFlag.lunchBudget),
        LunchTool.kidPicks => canEdit && flags.isOn(FeatureFlag.lunchKidPicks),
      };

  /// Which of [tools] are offered, in their order.
  static List<LunchTool> openOf(
    List<LunchTool> tools, {
    required bool canEdit,
    required FeatureFlags flags,
  }) => [
    for (final tool in tools)
      if (tool.isOpenTo(canEdit: canEdit, flags: flags)) tool,
  ];
}
