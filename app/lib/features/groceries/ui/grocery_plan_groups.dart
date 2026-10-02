import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/grocery_plan_copy.dart';
import '../model/grocery_plan_diff.dart';
import '../model/grocery_plan_line.dart';
import '../model/grocery_plan_selection.dart';
import 'grocery_proposal_row.dart';

/// The week's plans against the list, group by group (groceries ADR-0002):
/// what would change, ticked or not, then what is left alone and why.
class GroceryPlanGroups extends StatelessWidget {
  const GroceryPlanGroups({
    required this.diff,
    required this.selection,
    required this.onSelectionChanged,
    required this.onStaple,
    required this.now,
    super.key,
  });

  final GroceryPlanDiff diff;
  final GroceryPlanSelection selection;
  final VoidCallback onSelectionChanged;
  final void Function(String key, {required bool isStaple}) onStaple;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    void toggle(void Function() change) {
      change();
      onSelectionChanged();
    }

    GroceryRowAction stapleAction(GroceryPlanLine line) => (
      icon: LucideIcons.house,
      label: GroceryPlanCopy.markStapleFor(line.name),
      onPressed: () => onStaple(line.key, isStaple: true),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Group(
          title: GroceryPlanCopy.toAdd,
          rows: [
            for (final line in diff.toAdd)
              GroceryProposalRow(
                key: ValueKey('add-${line.key}'),
                name: line.name,
                quantity: line.quantity,
                detail: line.note,
                isTicked: selection.isAddTicked(line.key),
                onToggle: () => toggle(() => selection.toggleAdd(line.key)),
                action: stapleAction(line),
              ),
          ],
        ),
        _Group(
          title: GroceryPlanCopy.toRefresh,
          rows: [
            for (final (:line, :item) in diff.toRefresh)
              GroceryProposalRow(
                key: ValueKey('refresh-${item.id}'),
                name: item.name,
                quantity: item.quantity,
                detail: line.note,
                status: switch (line.quantity) {
                  final quantity? => GroceryPlanCopy.now(quantity),
                  null => GroceryPlanCopy.nowNoAmount,
                },
                isTicked: selection.isRefreshTicked(item.id),
                onToggle: () => toggle(() => selection.toggleRefresh(item.id)),
              ),
          ],
        ),
        _Group(
          title: GroceryPlanCopy.toRemove,
          rows: [
            for (final item in diff.toRemove)
              GroceryProposalRow(
                key: ValueKey('remove-${item.id}'),
                name: item.name,
                quantity: item.quantity,
                detail: item.sourceNote ?? GroceryPlanCopy.fromPlans,
                status: GroceryPlanCopy.removeBecause,
                isTicked: selection.isRemovalTicked(item.id),
                onToggle: () => toggle(() => selection.toggleRemoval(item.id)),
              ),
          ],
        ),
        _Group(
          title: GroceryPlanCopy.recentlyBought,
          rows: [
            for (final (:line, :item) in diff.recentlyBought)
              GroceryProposalRow(
                key: ValueKey('again-${line.key}'),
                name: line.name,
                quantity: line.quantity,
                detail: line.note,
                status: GroceryPlanCopy.boughtAgo(
                  now.difference(item.boughtAt ?? now),
                ),
                isTicked: selection.isAddAgainTicked(line.key),
                onToggle: () =>
                    toggle(() => selection.toggleAddAgain(line.key)),
                action: stapleAction(line),
              ),
          ],
        ),
        _Group(
          title: GroceryPlanCopy.added,
          rows: [
            for (final (:line, :item) in diff.added)
              GroceryProposalRow(
                key: ValueKey('added-${item.id}'),
                name: item.name,
                quantity: item.quantity,
                detail: line.note,
              ),
          ],
        ),
        _Group(
          title: GroceryPlanCopy.onList,
          rows: [
            for (final (:line, :item) in diff.onList)
              GroceryProposalRow(
                key: ValueKey('on-${item.id}'),
                name: item.name,
                quantity: item.quantity,
                detail: line.note,
              ),
          ],
        ),
        _Group(
          title: GroceryPlanCopy.staples,
          caption: GroceryPlanCopy.staplesBody,
          rows: [
            for (final line in diff.staples)
              GroceryProposalRow(
                key: ValueKey('staple-${line.key}'),
                name: line.name,
                detail: line.note,
                action: (
                  icon: LucideIcons.undo2,
                  label: GroceryPlanCopy.putBack(line.name),
                  onPressed: () => onStaple(line.key, isStaple: false),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// A heading and its rows; nothing at all when there are no rows.
class _Group extends StatelessWidget {
  const _Group({required this.title, required this.rows, this.caption});

  final String title;
  final String? caption;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();
    final nest = NestTheme.of(context);
    final text = caption;
    return Padding(
      padding: const EdgeInsets.only(top: NestSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NestSectionHeader(title: title),
          if (text != null) Text(text, style: nest.text.caption),
          const SizedBox(height: NestSpace.xs),
          ...rows,
        ],
      ),
    );
  }
}
