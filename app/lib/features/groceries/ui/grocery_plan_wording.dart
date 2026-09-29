import '../../../shared/copy/grocery_plan_copy.dart';
import '../../household/model/household_view.dart';
import '../model/grocery_plan_line.dart';
import '../model/grocery_proposal.dart';

/// Words a proposal once, for the sheet and for the item it becomes: its
/// quantity written out and its reasons as one sentence, with each child
/// named as the household knows them (groceries ADR-0002, ADR-0003).
///
/// It lives with the screens because it is copy; the controller is handed it
/// and never imports a word.
GroceryPlanLine Function(GroceryProposal) groceryPlanWording(
  HouseholdView household,
) =>
    (proposal) => GroceryPlanLine(
      proposal: proposal,
      quantity: GroceryPlanCopy.quantity(proposal.quantity),
      note: GroceryPlanCopy.reasons(
        proposal.reasons,
        nameOf: (memberId) => household.memberById(memberId)?.displayName,
      ),
    );
