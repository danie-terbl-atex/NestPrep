import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/grocery_plan_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../model/grocery_plan_selection.dart';
import '../model/grocery_plan_view.dart';
import 'grocery_keep_in_step_card.dart';
import 'grocery_plan_empty.dart';
import 'grocery_plan_groups.dart';

/// Where a planning shortcut in the empty sheet leads.
enum GroceryPlanDestination { meals, lunch }

/// What *From this week's plans* shows once the week has loaded: the switch,
/// the groups, and the one button that writes what is ticked.
class GroceryPlanContent extends StatelessWidget {
  const GroceryPlanContent({
    required this.view,
    required this.selection,
    required this.now,
    required this.onSelectionChanged,
    required this.onKeepInStep,
    required this.onStaple,
    required this.onApply,
    required this.onPlan,
    this.changedBy,
    super.key,
  });

  final GroceryPlanView view;
  final GroceryPlanSelection selection;
  final DateTime now;
  final String? changedBy;
  final VoidCallback onSelectionChanged;
  final ValueChanged<bool> onKeepInStep;
  final void Function(String key, {required bool isStaple}) onStaple;
  final VoidCallback onApply;
  final ValueChanged<GroceryPlanDestination> onPlan;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final diff = view.diff;
    final chosen = selection.countIn(diff);
    final canChoose = diff.hasChanges || diff.recentlyBought.isNotEmpty;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Flexible(
          child: ListView(
            shrinkWrap: true,
            children: [
              Text(
                GroceryPlanCopy.weekOf(NestDates.weekRange(view.week.monday)),
                style: nest.text.bodySecondary,
              ),
              const SizedBox(height: NestSpace.lg),
              GroceryKeepInStepCard(
                isOn: view.isKeptInStep,
                canChange: view.canKeepInStep,
                changedBy: changedBy,
                onChanged: onKeepInStep,
              ),
              if (diff.isEmpty)
                GroceryPlanEmpty(
                  onPlanMeals: () => onPlan(GroceryPlanDestination.meals),
                  onPlanLunches: () => onPlan(GroceryPlanDestination.lunch),
                )
              else ...[
                if (!diff.hasChanges)
                  const Padding(
                    padding: EdgeInsets.only(top: NestSpace.lg),
                    child: NestBanner(
                      message: GroceryPlanCopy.allOnTheList,
                      tone: NestBannerTone.success,
                    ),
                  ),
                GroceryPlanGroups(
                  diff: diff,
                  selection: selection,
                  now: now,
                  onSelectionChanged: onSelectionChanged,
                  onStaple: onStaple,
                ),
              ],
            ],
          ),
        ),
        if (canChoose) ...[
          const SizedBox(height: NestSpace.lg),
          NestButton(
            label: chosen == 0
                ? GroceryPlanCopy.nothingChosen
                : GroceryPlanCopy.apply(chosen),
            icon: LucideIcons.listChecks,
            onPressed: chosen == 0 ? null : onApply,
          ),
          const SizedBox(height: NestSpace.xs),
          NestButton(
            label: selection.hasUntickedIn(diff)
                ? GroceryPlanCopy.selectAll
                : GroceryPlanCopy.selectNone,
            variant: NestButtonVariant.ghost,
            size: NestButtonSize.small,
            onPressed: () {
              selection.setAll(diff, ticked: selection.hasUntickedIn(diff));
              onSelectionChanged();
            },
          ),
        ],
      ],
    );
  }
}
