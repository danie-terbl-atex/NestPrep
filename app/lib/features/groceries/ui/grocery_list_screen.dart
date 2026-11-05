import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/household_shell.dart';
import '../../../app/lists_switch.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/copy/grocery_plan_copy.dart';
import '../../../shared/flags/feature_flag.dart';
import '../../../shared/flags/feature_flags_controller.dart';
import '../../accounts/ui/account_menu_button.dart';
import '../../add_to_checkers/model/product_match_from.dart';
import '../../add_to_checkers/model/retailer_product.dart';
import '../../add_to_checkers/state/product_match_controller.dart';
import '../../add_to_checkers/state/product_type_ahead_controller.dart';
import '../../add_to_checkers/state/retailer_choice_controller.dart';
import '../../add_to_checkers/ui/checkers_item_footer.dart';
import '../../add_to_checkers/ui/find_at_checkers_button.dart';
import '../../add_to_checkers/ui/match_as_you_type_button.dart';
import '../../add_to_checkers/ui/product_type_ahead_card.dart';
import '../../add_to_checkers/ui/shop_carts_bar.dart';
import '../../add_to_checkers/ui/shops_on_list.dart';
import '../../basket_compare/ui/compare_shops_entry.dart';
import '../../household/model/household_area.dart';
import '../../household/model/household_view.dart';
import '../../list_scan/ui/snap_list_button.dart';
import '../../notifications/ui/notification_bell.dart';
import '../../welcome_tour/model/tour_target.dart';
import '../../welcome_tour/ui/tour_anchor.dart';
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
///
/// While somebody types, the chosen shop's products for it lead the list, so
/// one tap adds the item already matched (add-to-checkers ADR-0007).
class GroceryListScreen extends StatefulWidget {
  const GroceryListScreen({required this.onSelectTab, super.key});

  final ValueChanged<HouseholdTab> onSelectTab;

  @override
  State<GroceryListScreen> createState() => _GroceryListScreenState();
}

class _GroceryListScreenState extends State<GroceryListScreen> {
  final _name = TextEditingController();
  final _focus = FocusNode();
  RetailerChoiceController? _choice;
  var _isAddingPick = false;

  ValueChanged<HouseholdTab> get onSelectTab => widget.onSelectTab;

  @override
  void initState() {
    super.initState();
    _name.addListener(_lookUp);
    _choice = Provider.of<RetailerChoiceController?>(context, listen: false)
      ?..addListener(_lookUp);
  }

  @override
  void dispose() {
    _choice?.removeListener(_lookUp);
    _name.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// The shop's products for what is typed, while matching as you type is
  /// on and there is a shop to ask.
  void _lookUp() {
    final typeAhead = Provider.of<ProductTypeAheadController?>(
      context,
      listen: false,
    );
    final choice = _choice;
    if (typeAhead == null || choice == null) return;
    final canEdit = context.read<HouseholdView>().permissions.canEdit(
      HouseholdArea.groceries,
    );
    if (!canEdit ||
        !choice.matchesAsYouType ||
        shopsOnList(context, listen: false).isEmpty) {
      typeAhead.clear();
      return;
    }
    typeAhead.lookUp(_name.text, shop: choice.chosen);
  }

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
    final checkersOn = shopsOnList(context).isNotEmpty;
    final canSnap =
        canEdit &&
        (context.watch<FeatureFlagsController?>()?.isOn(
              FeatureFlag.snapShoppingList,
            ) ??
            false);
    final prompt = switch (plans.view) {
      AsyncData(value: final view)
          when canPlan && GroceryPlanPrompt.hasSomethingToSay(view) =>
        GroceryPlanPrompt(view: view, onReview: () => _openPlans(context)),
      _ => null,
    };
    // The chips belong to adding, not to the list, so they stay when the list
    // is empty — which is exactly when "the usual" is most useful. They scroll
    // with the list rather than sit under the add field: anything fixed above
    // the list takes its height from the one part that can give it back, and
    // at 200% text that leaves no list at all.
    final typeAhead =
        Provider.of<ProductTypeAheadController?>(context, listen: false) ==
                null ||
            !canEdit
        ? null
        : ProductTypeAheadCard(
            isAdding: _isAddingPick,
            onAdd: _addPicked,
            onJustAdd: _justAdd,
          );
    final suggestions = switch (controller.list) {
      AsyncData(value: final view)
          when canEdit && view.suggestions.isNotEmpty =>
        Padding(
          padding: const EdgeInsets.only(bottom: NestSpace.md),
          child: GrocerySuggestionChips(
            suggestions: view.suggestions,
            onTap: (suggestion) => _addSuggestion(context, suggestion),
          ),
        ),
      _ => null,
    };
    return NestScaffold(
      title: ListsSwitch.titleFor(
        context.watch<HouseholdView>().permissions,
        AppCopy.groceriesTitle,
      ),
      trailing: [
        if (canPlan)
          TourAnchor(
            target: TourTarget.groceryPlans,
            child: NestIconButton(
              icon: LucideIcons.listPlus,
              label: GroceryPlanCopy.open,
              onPressed: () => _openPlans(context),
            ),
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
          ListsSwitch(current: HouseholdTab.groceries, onSelect: onSelectTab),
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
              controller: _name,
              focusNode: _focus,
              leading: checkersOn ? const MatchAsYouTypeButton() : null,
              trailing: canSnap
                  ? SnapListButton(householdId: controller.householdId)
                  : null,
              onSubmit: (name, {quantity}) async {
                final added = await controller.add(name, quantity: quantity);
                if (context.mounted) _matchAfterAdding(context, added);
              },
            ),
          const SizedBox(height: NestSpace.md),
          Expanded(
            child: NestAsyncView<GroceryListView>(
              state: controller.list,
              isEmpty: (view) => view.isEmpty,
              onRetry: controller.retry,
              // An empty list is when the chips and the plans are most
              // useful, so they stay above the empty state rather than being
              // replaced by it (`FE-08`). The empty view sizes to what is
              // left, and scrolls under them when nothing is.
              emptyBuilder: (_) => CustomScrollView(
                slivers: [
                  if (typeAhead != null) SliverToBoxAdapter(child: typeAhead),
                  if (suggestions != null)
                    SliverToBoxAdapter(child: suggestions),
                  if (prompt != null) SliverToBoxAdapter(child: prompt),
                  const SliverFillRemaining(
                    hasScrollBody: false,
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
                typeAhead: typeAhead,
                suggestions: suggestions,
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

  Future<void> _addPicked(RetailerProduct product) async {
    final controller = context.read<GroceryListController>();
    setState(() => _isAddingPick = true);
    final added = await controller.addMatched(
      _name.text,
      productMatchFrom(product, pickedBy: controller.memberId),
    );
    if (!mounted) return;
    setState(() => _isAddingPick = false);
    if (!added) return;
    _name.clear();
    _focus.requestFocus();
  }

  Future<void> _justAdd() async {
    final name = _name.text;
    _name.clear();
    _focus.requestFocus();
    await context.read<GroceryListController>().add(name);
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
  /// add up — its matches are looked for at the chosen shop (the Checkers
  /// build contract, add-to-pnp ADR-0007).
  void _matchAfterAdding(BuildContext context, GroceryItem? added) {
    if (added == null || shopsOnList(context, listen: false).isEmpty) return;
    context.read<ProductMatchController>().lookFor(
      added,
      at: context.read<RetailerChoiceController>().chosen,
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
  const _GroceryList({
    required this.householdId,
    required this.view,
    required this.checkersOn,
    required this.canEdit,
    this.typeAhead,
    this.suggestions,
    this.header,
  });

  final String householdId;
  final GroceryListView view;
  final bool checkersOn;
  final bool canEdit;
  final Widget? typeAhead;
  final Widget? suggestions;
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: NestSize.bottomBarHeight * 2),
      children: [
        ?typeAhead,
        ?suggestions,
        if (header case final prompt?) ...[
          prompt,
          const SizedBox(height: NestSpace.lg),
        ],
        // Scrolls with the list, so at 200% text it never squeezes the list
        // out from under the add field.
        if (checkersOn && canEdit)
          ShopCartsBar(
            householdId: householdId,
            toBuy: view.toBuy,
            shops: shopsOnList(context),
          ),
        if (shopsOnList(context) case final shops
            when shops.length > 1 && view.toBuy.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: NestSpace.lg),
            child: CompareShopsEntry(householdId: householdId, shops: shops),
          ),
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
