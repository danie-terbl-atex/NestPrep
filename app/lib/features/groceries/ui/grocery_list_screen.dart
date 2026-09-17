import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/household_shell.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/copy/app_copy.dart';
import '../../accounts/ui/account_menu_button.dart';
import '../../household/ui/household_link_button.dart';
import '../model/grocery_list_view.dart';
import '../state/grocery_list_controller.dart';
import 'grocery_add_field.dart';
import 'grocery_item_row.dart';
import 'grocery_suggestion_chips.dart';

/// The one household list (groceries ADR-0001). This is the reference
/// implementation of a household-scoped live list: the other three features copy
/// its four states, its add-in-place row and its optimism about the network.
class GroceryListScreen extends StatelessWidget {
  const GroceryListScreen({required this.onSelectTab, super.key});

  final ValueChanged<HouseholdTab> onSelectTab;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GroceryListController>();
    final failure = controller.actionFailure;
    return NestScaffold(
      title: AppCopy.groceriesTitle,
      trailing: const [HouseholdLinkButton(), AccountMenuButton()],
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
                onAction: controller.dismissActionFailure,
              ),
            ),
          GroceryAddField(onSubmit: controller.add),
          // The chips belong to adding, not to the list, so they stay when the
          // list is empty — which is exactly when "the usual" is most useful.
          if (controller.list case AsyncData(value: final view)
              when view.suggestions.isNotEmpty) ...[
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
              emptyBuilder: (_) => const NestEmptyView(
                title: AppCopy.groceriesEmptyTitle,
                message: AppCopy.groceriesEmptyBody,
                icon: Icons.shopping_basket_outlined,
              ),
              dataBuilder: (_, view) => _GroceryList(view: view),
            ),
          ),
        ],
      ),
    );
  }
}

class _GroceryList extends StatelessWidget {
  const _GroceryList({required this.view});

  final GroceryListView view;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: NestSize.bottomBarHeight * 2),
      children: [
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
