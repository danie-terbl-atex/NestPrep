import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../../lunch_box/model/lunch_plan.dart';
import '../../lunch_box/model/lunch_slot.dart';
import '../model/shop_week.dart';
import '../state/plan_week_controller.dart';
import 'plan_week_item_pill.dart';
import 'plan_week_swap_sheet.dart';

/// One child's week on the review: whose it is, how much is new, and the
/// school days still to come — what was packed already, quiet; each new
/// shop product in the slot's colour, a tap from being swapped
/// to another product kept for this child, or cleared.
class PlanWeekChildCard extends StatelessWidget {
  const PlanWeekChildCard({
    required this.plan,
    required this.child,
    required this.isEditable,
    super.key,
  });

  final ShopWeek plan;
  final ShopChildWeek child;
  final bool isEditable;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final member = child.child.member;
    final labelChecks = plan.labelChecksFor(child);
    return NestCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              NestAvatar(name: member.displayName, color: member.color),
              const SizedBox(width: NestSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(member.displayName, style: nest.text.title),
                    const SizedBox(height: NestSpace.xs),
                    NestTag(
                      label: PlanWeekCopy.newForChild(child.added.length),
                      tone: child.added.isEmpty
                          ? NestTagTone.neutral
                          : NestTagTone.success,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (labelChecks.isNotEmpty) ...[
            const SizedBox(height: NestSpace.md),
            NestBanner(
              key: ValueKey('plan-label-check-${child.childId}'),
              message: PlanWeekCopy.labelCheckOf(
                labelChecks.first.product.retailer,
                [for (final product in labelChecks) product.product.name],
              ),
              tone: NestBannerTone.warning,
            ),
          ],
          for (final day in plan.week.schoolDays)
            if (plan.daysLeft.contains(day.weekday)) ...[
              const SizedBox(height: NestSpace.lg),
              Text(
                NestDates.weekdayName(day),
                style: nest.text.caption.copyWith(
                  color: nest.colors.inkSecondary,
                ),
              ),
              const SizedBox(height: NestSpace.xs),
              Wrap(
                spacing: NestSpace.xs,
                runSpacing: NestSpace.xs,
                children: [
                  for (final slot in LunchSlot.values)
                    ?_pillFor(
                      context,
                      day.weekday,
                      slot,
                      NestDates.weekdayName(day),
                    ),
                ],
              ),
            ],
        ],
      ),
    );
  }

  Widget? _pillFor(BuildContext context, int day, LunchSlot slot, String name) {
    final existing = child.existing.pickAt(day, slot);
    if (existing != null) {
      return PlanWeekItemPill(
        slot: slot,
        look: PillLook.existing,
        name: existing.name,
      );
    }
    final added = child.addedAt(day, slot);
    if (added == null && !plan.fills(day, slot)) return null;
    final product = added == null ? null : plan.productOf(added);
    final caution = [
      if (added != null)
        for (final bought in plan.boughtFor(added))
          if (bought.needsLabelCheckFor(child.childId))
            PlanWeekCopy.labelCheck(bought.product.retailer),
    ].firstOrNull;
    return PlanWeekItemPill(
      key: ValueKey('plan-pill-${child.childId}-$day-${slot.name}'),
      slot: slot,
      look: added == null ? PillLook.empty : PillLook.added,
      name:
          product?.product.name ??
          (added == null ? null : plan.dishOf(added)?.draft.name),
      origin: added?.origin,
      product: product?.product,
      caution: caution,
      onTap: isEditable
          ? () => _swap(context, day: day, slot: slot, dayName: name)
          : null,
    );
  }

  Future<void> _swap(
    BuildContext context, {
    required int day,
    required LunchSlot slot,
    required String dayName,
  }) async {
    final controller = context.read<PlanWeekController>();
    final shop = controller.shop;
    final choice = await showPlanWeekSwapSheet(
      context: context,
      title: PlanWeekCopy.swapTitle(LunchCopy.slotName(slot), dayName),
      childId: child.childId,
      options: plan.optionsFor(child.childId, slot),
      current: child.addedAt(day, slot),
      boxesPerPackOf: plan.boxesPerPackOf,
      everyDay: controller.variety.variety.keepsSame(slot),
    );
    if (choice == null) return;
    final pick = switch (choice) {
      SwapToProduct(:final ideaId, :final productId) => ShopPick(
        ideaId: ideaId,
        productId: productId,
        origin: PickOrigin.swapped,
      ),
      SwapToEmpty() => null,
    };
    if (choice.everyDay) {
      shop.swapEveryDay(child.childId, day, slot, pick);
    } else {
      shop.swap(child.childId, LunchPlan.slotKey(day, slot), pick);
    }
  }
}
