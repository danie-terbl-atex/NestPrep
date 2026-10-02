import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/ui/back_leading.dart';
import '../../household/model/household_area.dart';
import '../../household/model/household_view.dart';
import '../../subscriptions/state/household_entitlement.dart';
import '../model/lunch_budget_week.dart';
import '../state/lunch_budget_controller.dart';
import 'lunch_budget_flows.dart';
import 'lunch_budget_locked.dart';
import 'lunch_price_row.dart';

/// Every library item and its price (lunch-box ADR-0007) — the unpriced
/// first, so the list says what is left to do. Built lazily: a library can
/// run to hundreds of items (`FE-11`).
class LunchPricesScreen extends StatelessWidget {
  const LunchPricesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final budget = context.watch<LunchBudgetController>();
    final isPremium = context.watch<HouseholdEntitlement>().isPremium;
    final canEdit = context.watch<HouseholdView>().permissions.canEdit(
      HouseholdArea.lunch,
    );
    final failure = budget.actionFailure;
    return NestScaffold(
      title: LunchBudgetCopy.pricesTitle,
      subtitle: LunchBudgetCopy.pricesSubtitle,
      leading: backLeading(context),
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
                onAction: budget.dismissActionFailure,
              ),
            ),
          Expanded(
            child: !isPremium
                ? const LunchBudgetLocked()
                : NestAsyncView<LunchBudgetWeek>(
                    state: budget.week,
                    isEmpty: (week) => week.pricingOrder.isEmpty,
                    onRetry: budget.retry,
                    emptyBuilder: (_) => const NestEmptyView(
                      icon: LucideIcons.bookOpen,
                      title: LunchCopy.libraryTitle,
                      message: LunchCopy.libraryLoadingSeed,
                    ),
                    dataBuilder: (context, week) {
                      final items = week.pricingOrder;
                      return ListView.builder(
                        padding: const EdgeInsets.only(bottom: NestSpace.huge),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return LunchPriceRow(
                            key: ValueKey(item.id),
                            item: item,
                            price: week.priceOf(item.id),
                            onTap: canEdit
                                ? () => LunchBudgetFlows.editPrice(
                                    context,
                                    week: week,
                                    item: item,
                                  )
                                : null,
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
