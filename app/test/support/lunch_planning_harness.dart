import 'package:nestprep/features/lunch_box/model/lunch_budget.dart';
import 'package:nestprep/features/lunch_box/model/lunch_choices.dart';
import 'package:nestprep/features/lunch_box/model/lunch_packed_day.dart';
import 'package:nestprep/features/lunch_box/model/lunch_pantry_entry.dart';
import 'package:nestprep/features/lunch_box/model/lunch_price.dart';
import 'package:nestprep/features/lunch_box/state/lunch_board_controller.dart';
import 'package:nestprep/features/lunch_box/state/lunch_budget_controller.dart';
import 'package:nestprep/features/lunch_box/state/lunch_choices_controller.dart';
import 'package:nestprep/features/lunch_box/state/lunch_pantry_controller.dart';
import 'package:nestprep/features/lunch_box/state/lunch_pantry_groceries.dart';
import 'package:nestprep/shared/flags/feature_flags.dart';
import 'package:nestprep/shared/flags/feature_flags_controller.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'fake_grocery_repository.dart';
import 'fake_lunch_planning.dart';
import 'household_fixtures.dart';
import 'lunch_harness.dart';
import 'test_flags.dart';

/// The lunch board and its V2 tools (lunch-box ADR-0006 to ADR-0008) over
/// fakes, following the board the way the lunch shell wires them — the one
/// setup every pantry, budget and kid-picks test starts from.
final class LunchPlanningHarness {
  LunchPlanningHarness({FeatureFlags flags = TestFlags.on}) {
    this.flags = testFlagsController(flags);
    pantry = LunchPantryController(
      pantryRepository: pantryRepository,
      lunchRepository: lunch.repository,
      groceries: LunchPantryGroceries(
        groceryRepository: groceries,
        householdId: Fixtures.householdId,
        memberId: Fixtures.samMemberId,
      ),
      householdId: Fixtures.householdId,
      memberId: Fixtures.samMemberId,
    );
    budget = LunchBudgetController(
      budgetRepository: budgetRepository,
      householdId: Fixtures.householdId,
      memberId: Fixtures.samMemberId,
    );
    choices = LunchChoicesController(
      choicesRepository: choicesRepository,
      householdId: Fixtures.householdId,
      memberId: Fixtures.samMemberId,
    );
    board.addListener(_follow);
    _follow();
  }

  final lunch = LunchHarness();
  final pantryRepository = FakeLunchPantryRepository();
  final budgetRepository = FakeLunchBudgetRepository();
  final choicesRepository = FakeLunchChoicesRepository();
  final groceries = FakeGroceryRepository();
  late final FeatureFlagsController flags;
  late final LunchPantryController pantry;
  late final LunchBudgetController budget;
  late final LunchChoicesController choices;

  LunchBoardController get board => lunch.controller;

  void _follow() {
    pantry.followBoard(board.board, board.week);
    budget.followBoard(board.board);
    choices.followBoard(board.board, board.week);
  }

  /// What a screen under the lunch shell has above it.
  List<SingleChildWidget> get providers => [
    ChangeNotifierProvider<FeatureFlagsController>.value(value: flags),
    ChangeNotifierProvider<LunchBoardController>.value(value: board),
    ChangeNotifierProvider<LunchPantryController>.value(value: pantry),
    ChangeNotifierProvider<LunchBudgetController>.value(value: budget),
    ChangeNotifierProvider<LunchChoicesController>.value(value: choices),
  ];

  /// The V2 reads, answering at once (after `LunchHarness.emit`).
  void emitPlanning({
    List<LunchPantryEntry> pantry = const [],
    List<LunchPackedDay> packed = const [],
    List<LunchPrice> prices = const [],
    LunchBudget? budget,
    List<LunchChoices> choices = const [],
  }) {
    pantryRepository
      ..emitPantry(pantry)
      ..emitPacked(packed);
    budgetRepository
      ..emitPrices(prices)
      ..emitBudget(budget);
    choicesRepository.emitWeek(choices);
  }

  Future<void> close() async {
    board.removeListener(_follow);
    pantry.dispose();
    budget.dispose();
    choices.dispose();
    flags.dispose();
    await pantryRepository.close();
    await budgetRepository.close();
    await choicesRepository.close();
    await groceries.close();
    await lunch.close();
  }
}
