import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/household_shell.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/copy/grocery_plan_copy.dart';
import '../../accounts/ui/account_menu_button.dart';
import '../../household/model/household_area.dart';
import '../../household/model/household_view.dart';
import '../../household/ui/household_link_button.dart';
import '../../notifications/ui/notification_bell.dart';
import '../model/grocery_list_view.dart';
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
        const HouseholdLinkButton(),
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
          if (canEdit) GroceryAddField(onSubmit: controller.add),
          // The chips belong to adding, not to the list, so they stay when the
          // list is empty — which is exactly when "the usual" is most useful.
          if (controller.list case AsyncData(value: final view)
              when canEdit && view.suggestions.isNotEmpty) ...[
            const SizedBox(height: NestSpace.md),
            GrocerySuggestionChips(
              suggestions: view.suggestions,
              onTap: controller.addFromSuggestion,
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
              dataBuilder: (_, view) =>
                  _GroceryList(view: view, header: prompt),
            ),
          ),
        ],
      ),
    );
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
  const _GroceryList({required this.view, this.header});

  final GroceryListView view;
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
        if (view.toBuy.isNotEmpty) ...[
          const NestSectionHeader(title: AppCopy.groceriesToBuy),
          const SizedBox(height: NestSpace.sm),
          for (final item in view.toBuy)
            Padding(
              padding: const EdgeInsets.only(bottom: NestSpace.sm),
              child: GroceryItemRow(key: ValueKey(item.id), item: item),
            ),
        ],
        if (view.justBought.isNotEmpty) ...[
          const SizedBox(height: NestSpace.lg),
          const NestSectionHeader(title: AppCopy.groceriesBought),
          const SizedBox(height: NestSpace.sm),
          for (final item in view.justBought)
            Padding(
              padding: const EdgeInsets.only(bottom: NestSpace.sm),
              child: GroceryItemRow(key: ValueKey(item.id), item: item),
            ),
        ],
      ],
    );
  }
}
