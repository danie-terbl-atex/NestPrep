import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/shift.dart';
import '../model/shift_checklist.dart';
import '../model/shift_moment.dart';
import 'moment_look.dart';

/// This shift's checklists: the part of the evening as chips — each saying
/// how much of it is done — and that part's list as big rows to tick. It opens
/// on the first part with something left to do. Ticks are the shift's own;
/// the list is the parents' (nanny-hub ADR-0001).
class ShiftChecklistPanel extends StatefulWidget {
  const ShiftChecklistPanel({
    required this.checklists,
    required this.shift,
    required this.canTick,
    required this.onTick,
    super.key,
  });

  final List<ShiftChecklist> checklists;
  final Shift shift;
  final bool canTick;
  final void Function(ShiftMoment moment, String itemId, bool isTicked) onTick;

  @override
  State<ShiftChecklistPanel> createState() => _ShiftChecklistPanelState();
}

class _ShiftChecklistPanelState extends State<ShiftChecklistPanel> {
  ShiftMoment? _chosen;

  List<(ShiftMoment, ShiftChecklist)> get _withItems => [
    for (final checklist in widget.checklists)
      if (checklist.moment case final moment? when checklist.items.isNotEmpty)
        (moment, checklist),
  ];

  int _done(ShiftMoment moment, ShiftChecklist checklist) => checklist.items
      .where(
        (item) =>
            widget.shift.isTicked(ShiftChecklist.tickKey(moment, item.id)),
      )
      .length;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final lists = _withItems;
    if (lists.isEmpty) return const SizedBox.shrink();
    final open = lists.where(
      (list) => _done(list.$1, list.$2) < list.$2.items.length,
    );
    final (moment, checklist) = lists.firstWhere(
      (list) => list.$1 == _chosen,
      orElse: () => open.firstOrNull ?? lists.first,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(NannyShiftCopy.checklistNow, style: nest.text.title),
        const SizedBox(height: NestSpace.sm),
        Wrap(
          spacing: NestSpace.sm,
          runSpacing: NestSpace.sm,
          children: [
            for (final (option, list) in lists)
              NestChip(
                label:
                    '${NannyCopy.momentName(option)} · '
                    '${_done(option, list)}/${list.items.length}',
                icon: option.icon,
                isSelected: option == moment,
                onTap: () => setState(() => _chosen = option),
              ),
          ],
        ),
        const SizedBox(height: NestSpace.md),
        Text(
          NannyShiftCopy.ticked(
            _done(moment, checklist),
            checklist.items.length,
          ),
          style: nest.text.caption,
        ),
        const SizedBox(height: NestSpace.sm),
        for (final item in checklist.items)
          Padding(
            key: ValueKey('${moment.name}:${item.id}'),
            padding: const EdgeInsets.only(bottom: NestSpace.xs),
            child: _TickRow(
              text: item.text,
              isTicked: widget.shift.isTicked(
                ShiftChecklist.tickKey(moment, item.id),
              ),
              onChanged: widget.canTick
                  ? (isTicked) => widget.onTick(moment, item.id, isTicked)
                  : null,
            ),
          ),
      ],
    );
  }
}

class _TickRow extends StatelessWidget {
  const _TickRow({
    required this.text,
    required this.isTicked,
    required this.onChanged,
  });

  final String text;
  final bool isTicked;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final change = onChanged;
    return Semantics(
      container: true,
      checked: isTicked,
      label: text,
      excludeSemantics: true,
      onTap: change == null ? null : () => change(!isTicked),
      child: NestCard(
        variant: isTicked ? NestCardVariant.tinted : NestCardVariant.flat,
        padding: const EdgeInsets.all(NestSpace.md),
        onTap: change == null ? null : () => change(!isTicked),
        child: Row(
          children: [
            Icon(
              isTicked ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isTicked ? nest.colors.success : nest.colors.inkTertiary,
              size: NestSize.iconLarge,
            ),
            const SizedBox(width: NestSpace.md),
            Expanded(
              child: Text(
                text,
                style: nest.text.body.copyWith(
                  decoration: isTicked ? TextDecoration.lineThrough : null,
                  color: isTicked ? nest.colors.inkSecondary : nest.colors.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
