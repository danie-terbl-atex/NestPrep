import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../lunch_box/model/lunch_slot.dart';
import '../model/lunch_idea.dart';

/// A parent's own idea: which compartment, and what to look for.
typedef OwnIdea = ({LunchSlot slot, String text});

/// The sheet offers only the compartments in [slots] — the ones the brief
/// fills.
Future<OwnIdea?> showPlanWeekIdeaSheet(
  BuildContext context, {
  required Set<LunchSlot> slots,
}) => showNestSheet<OwnIdea>(
  context: context,
  title: PlanWeekCopy.addIdeaTitle,
  builder: (_) => _IdeaForm(
    slots: [
      for (final slot in LunchSlot.values)
        if (slots.contains(slot)) slot,
    ],
  ),
);

class _IdeaForm extends StatefulWidget {
  const _IdeaForm({required this.slots});

  final List<LunchSlot> slots;

  @override
  State<_IdeaForm> createState() => _IdeaFormState();
}

class _IdeaFormState extends State<_IdeaForm> {
  final _text = TextEditingController();
  late var _slot = widget.slots.first;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = _text.text.trim();
    final isTooLong = text.length > LunchIdea.textLimit;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: NestSpace.sm,
          runSpacing: NestSpace.sm,
          children: [
            for (final slot in widget.slots)
              NestChip(
                key: ValueKey('idea-slot-${slot.name}'),
                label: LunchCopy.slotName(slot),
                isSelected: slot == _slot,
                onTap: () => setState(() => _slot = slot),
              ),
          ],
        ),
        const SizedBox(height: NestSpace.md),
        NestTextField(
          key: const ValueKey('idea-text'),
          label: PlanWeekCopy.ideaField,
          hint: PlanWeekCopy.ideaHint,
          controller: _text,
          autofocus: true,
          errorText: isTooLong ? PlanWeekCopy.ideaTooLong : null,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: NestSpace.lg),
        NestButton(
          label: PlanWeekCopy.ideaSave,
          onPressed: text.isEmpty || isTooLong
              ? null
              : () => Navigator.of(context).pop((slot: _slot, text: text)),
        ),
      ],
    );
  }
}
