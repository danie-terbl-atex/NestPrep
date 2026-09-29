import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/lunch_board.dart';

/// Which child's week is open — one chip each, the open one selected. Each
/// child's grid is their own: their rules, their history, their go-to boxes.
/// Nothing to choose with one child, so nothing is shown.
class LunchChildSwitcher extends StatelessWidget {
  const LunchChildSwitcher({
    required this.children,
    required this.selectedChildId,
    required this.onSelect,
    super.key,
  });

  final List<LunchChildWeek> children;
  final String? selectedChildId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    if (children.length < 2) return const SizedBox.shrink();
    return Wrap(
      spacing: NestSpace.sm,
      runSpacing: NestSpace.sm,
      children: [
        for (final childWeek in children)
          NestChip(
            key: ValueKey(childWeek.childId),
            label: childWeek.child.member.displayName,
            semanticLabel: LunchCopy.chooseChild(
              childWeek.child.member.displayName,
            ),
            icon: childWeek.unsafeCount > 0 ? Icons.error_outline : null,
            isSelected: childWeek.childId == selectedChildId,
            onTap: () => onSelect(childWeek.childId),
          ),
      ],
    );
  }
}
