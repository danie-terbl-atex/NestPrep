import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/household_shell.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/copy/grocery_plan_copy.dart';
import '../../accounts/ui/account_menu_button.dart';
import '../../add_to_checkers/state/product_match_controller.dart';
import '../../add_to_checkers/ui/checkers_is_on.dart';
import '../../add_to_checkers/ui/checkers_item_footer.dart';
import '../../add_to_checkers/ui/checkers_list_bar.dart';
import '../../add_to_checkers/ui/find_at_checkers_button.dart';
import '../../add_to_checkers/ui/retailer_choice_bar.dart';
import '../../household/model/household_area.dart';
import '../../household/model/household_view.dart';
import '../../notifications/ui/notification_bell.dart';
import '../model/grocery_item.dart';
import '../model/grocery_list_view.dart';
import '../model/grocery_suggestion.dart';
import '../state/grocery_list_controller.dart';
import '../state/grocery_plan_controller.dart';
import 'grocery_add_field.dart';
import 'grocery_item_row.dart';
import 'grocery_plan_content.dart';
import 'grocery_plan_prompt.dart';
import 'grocery_plan_sheet.dart';
import 'grocery_suggestion_chips.dart';

/// The one household list (groceries ADR-0002). This is the reference
/// implementation of a household-scoped live list: the other three features copy
/// its four states, its add-in-place row and its optimism about the network.
///
/// Above the list, the week's meals and lunch boxes offer what they need —
/// and nothing lands on the list until somebody says so, or has asked for it
/// to be kept in step.
class GroceryListScreen extends StatelessWidget {
  const GroceryListScreen({required this.onSelectTab, super.key});

  final ValueChanged<HouseholdTab> onSelectTab;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GroceryListController>();
    final plans = context.watch<GroceryPlanController>();
    final failure = controller.actionFailure ?? plans.actionFailure;
    // A list somebody may only read has no field to add to (household
    // ADR-0003); the rules refuse the write either way.
    final canEdit = context.watch<HouseholdView>().permissions.canEdit(
      HouseholdArea.groceries,
    );
    final canPlan = canEdit && plans.hasSources;
    final checkersOn = isCheckersOn(context);
    final prompt = switch (plans.view) {
      AsyncData(value: final view)
          when canPlan && GroceryPlanPrompt.hasSomethingToSay(view) =>
        GroceryPlanPrompt(view: view, onReview: () => _openPlans(context)),
      _ => null,
    };
    return NestScaffold(
      title: AppCopy.groceriesTitle,
      trailing: [
        if (canPlan)
          NestIconButton(
            icon: Icons.playlist_add_rounded,
            label: GroceryPlanCopy.open,
            onPressed: () => _openPlans(context),
          ),
        const NotificationBell(),
        const AccountMenuButton(),
      ],
      bottomBar: HouseholdTabBar(
        current: HouseholdTab.groceries,
        onSelect: onSelectTab,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (failure != null)
            Padding(
              padding: const EdgeInsets.only(bottom: NestSpace.md),
              child: NestBanner(
                message: AppCopy.failure(failure),
                tone: NestBannerTone.danger,
                actionLabel: AppCopy.back,
                onAction: () {
                  controller.dismissActionFailure();
                  plans.dismissActionFailure();
                },
              ),
            ),
          if (canEdit)
            GroceryAddField(
              onSubmit: (name, {quantity}) async {
                final added = await controller.add(name, quantity: quantity);
                if (context.mounted) _matchAfterAdding(context, added);
              },
            ),
          // The chips belong to adding, not to the list, so they stay when the
          // list is empty — which is exactly when "the usual" is most useful.
          if (controller.list case AsyncData(value: final view)
              when canEdit && view.suggestions.isNotEmpty) ...[
            const SizedBox(height: NestSpace.md),
            GrocerySuggestionChips(
              suggestions: view.suggestions,
              onTap: (suggestion) => _addSuggestion(context, suggestion),
            ),
          ],

          const SizedBox(height: NestSpace.md),
          Expanded(
            child: NestAsyncView<GroceryListView>(
              state: controller.list,
              isEmpty: (view) => view.isEmpty,
              onRetry: controller.retry,
              // An empty list is when the plans are most useful, so their
              // prompt stays above the empty state rather than being replaced
              // by it (`FE-08`).
              emptyBuilder: (_) => CustomScrollView(
                slivers: [
                  if (prompt != null) SliverToBoxAdapter(child: prompt),
                  const SliverFillRemaining(
                    child: NestEmptyView(
                      title: AppCopy.groceriesEmptyTitle,
                      message: AppCopy.groceriesEmptyBody,
                    ),
                  ),
                ],
              ),
              dataBuilder: (_, view) => _GroceryList(
                householdId: controller.householdId,
                view: view,
                header: prompt,
                checkersOn: checkersOn,
                canEdit: canEdit,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addSuggestion(
    BuildContext context,
    GrocerySuggestion suggestion,
  ) async {
    final controller = context.read<GroceryListController>();
    final added = await controller.addFromSuggestion(suggestion);
    if (context.mounted) _matchAfterAdding(context, added);
  }

  /// Once an item is safely on the list — never before, and never holding the
  /// add up — its Checkers matches are looked for (the Checkers build
  /// contract).
  void _matchAfterAdding(BuildContext context, GroceryItem? added) {
    if (added == null || !isCheckersOn(context, listen: false)) return;
    context.read<ProductMatchController>().lookFor(added);
  }

  void _openPlans(BuildContext context) => showGroceryPlanSheet(
    context: context,
    onPlan: (destination) => onSelectTab(switch (destination) {
      GroceryPlanDestination.meals => HouseholdTab.meals,
      GroceryPlanDestination.lunch => HouseholdTab.lunch,
    }),
  );
}

class _GroceryList extends StatelessWidget {
  const _GroceryList({
    required this.householdId,
    required this.view,
    required this.checkersOn,
    required this.canEdit,
    this.header,
  });

  final String householdId;
  final GroceryListView view;
  final bool checkersOn;
  final bool canEdit;
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: NestSize.bottomBarHeight * 2),
      children: [
        if (header case final prompt?) ...[
          prompt,
          const SizedBox(height: NestSpace.lg),
        ],
        // Both scroll with the list, so at 200% text they never squeeze the
        // list out from under the add field.
        if (checkersOn && canEdit) ...[
          const RetailerChoiceBar(),
          CheckersListBar(householdId: householdId, matched: view.matchedToBuy),
        ],
        if (view.toBuy.isNotEmpty) ...[
          const NestSectionHeader(title: AppCopy.groceriesToBuy),
          const SizedBox(height: NestSpace.sm),
          for (final item in view.toBuy)
            Padding(
              padding: const EdgeInsets.only(bottom: NestSpace.sm),
              child: _GroceryListRow(
                key: ValueKey(item.id),
                item: item,
                checkersOn: checkersOn,
                canEdit: canEdit,
              ),
            ),
        ],
        if (view.justBought.isNotEmpty) ...[
          const SizedBox(height: NestSpace.lg),
          const NestSectionHeader(title: AppCopy.groceriesBought),
          const SizedBox(height: NestSpace.sm),
          for (final item in view.justBought)
            Padding(
              padding: const EdgeInsets.only(bottom: NestSpace.sm),
              child: _GroceryListRow(
                key: ValueKey(item.id),
                item: item,
                checkersOn: checkersOn,
                canEdit: canEdit,
              ),
            ),
        ],
      ],
    );
  }
}

/// One row of the list, with what Checkers adds to it when it is on: the
/// chosen shop's logo (*Find at Checkers*) beside an unmatched item, and the
/// picked product under it.
class _GroceryListRow extends StatelessWidget {
  const _GroceryListRow({
    required this.item,
    required this.checkersOn,
    required this.canEdit,
    super.key,
  });

  final GroceryItem item;
  final bool checkersOn;
  final bool canEdit;

  @override
  Widget build(BuildContext context) => GroceryItemRow(
    item: item,
    trailing:
        checkersOn && canEdit && !item.isBought && item.productMatch == null
        ? FindAtCheckersButton(item: item)
        : null,
    footer: checkersOn
        ? CheckersItemFooter(item: item, canEdit: canEdit)
        : null,
  );
}
