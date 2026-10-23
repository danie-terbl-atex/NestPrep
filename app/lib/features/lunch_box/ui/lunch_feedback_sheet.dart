import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../family_profiles/ui/sheet_label.dart';
import '../../family_profiles/ui/sheet_outcome.dart';
import '../model/lunch_box.dart';
import '../model/lunch_feedback.dart';
import '../model/lunch_slot.dart';

/// The box's verdict and the marks one item at a time.
typedef LunchMarks = ({LunchVerdict box, Map<LunchSlot, LunchVerdict> items});

/// Item by item: what came home eaten and what did not (lunch-box
/// ADR-0003). A thing somebody does not mark is judged with the box; one they
/// mark counts for more in the learning than the box's verdict does.
Future<SheetOutcome<LunchMarks>?> showLunchFeedbackSheet({
  required BuildContext context,
  required LunchBox box,
  required LunchFeedback? existing,
}) => showNestSheet<SheetOutcome<LunchMarks>>(
  context: context,
  title: LunchCopy.markItemsTitle,
  builder: (_) => _FeedbackBody(box: box, existing: existing),
);

class _FeedbackBody extends StatefulWidget {
  const _FeedbackBody({required this.box, required this.existing});

  final LunchBox box;
  final LunchFeedback? existing;

  @override
  State<_FeedbackBody> createState() => _FeedbackBodyState();
}

class _FeedbackBodyState extends State<_FeedbackBody> {
  late LunchVerdict _box = widget.existing?.boxVerdict ?? LunchVerdict.ate;
  late final Map<LunchSlot, LunchVerdict> _items = {
    for (final (slot, _) in widget.box.filled)
      if (widget.existing?.isMarkedOnItsOwn(slot) ?? false)
        slot: widget.existing!.verdictFor(slot)!,
  };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _VerdictChoice(
            label: LunchCopy.cameHomeQuestion,
            selected: _box,
            onSelect: (verdict) => setState(() => _box = verdict),
          ),
          for (final (slot, pick) in widget.box.filled) ...[
            const SizedBox(height: NestSpace.lg),
            _VerdictChoice(
              label: '${LunchCopy.slotName(slot)} · ${pick.name}',
              selected: _items[slot],
              onSelect: (verdict) => setState(() => _items[slot] = verdict),
            ),
          ],
          const SizedBox(height: NestSpace.xxl),
          NestButton(
            label: LunchCopy.saveMarks,
            onPressed: () => Navigator.of(context)
                .pop(SheetSaved<LunchMarks>((box: _box, items: {..._items}))),
          ),
          if (widget.existing != null) ...[
            const SizedBox(height: NestSpace.sm),
            NestButton(
              label: LunchCopy.undoMark,
              variant: NestButtonVariant.ghost,
              icon: LucideIcons.undo2,
              onPressed: () =>
                  Navigator.of(context).pop(const SheetRemoved<LunchMarks>()),
            ),
          ],
        ],
      ),
    );
  }
}

class _VerdictChoice extends StatelessWidget {
  const _VerdictChoice({
    required this.label,
    required this.selected,
    required this.onSelect,
  });

  final String label;
  final LunchVerdict? selected;
  final ValueChanged<LunchVerdict> onSelect;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SheetLabel(label),
      Wrap(
        spacing: NestSpace.sm,
        runSpacing: NestSpace.sm,
        children: [
          NestChip(
            label: LunchCopy.ateIt,
            icon: LucideIcons.thumbsUp,
            isSelected: selected == LunchVerdict.ate,
            onTap: () => onSelect(LunchVerdict.ate),
          ),
          NestChip(
            label: LunchCopy.leftIt,
            icon: LucideIcons.thumbsDown,
            isSelected: selected == LunchVerdict.left,
            onTap: () => onSelect(LunchVerdict.left),
          ),
        ],
      ),
    ],
  );
}
