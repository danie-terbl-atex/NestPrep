import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../model/lunch_choices.dart';
import '../model/lunch_day.dart';
import '../model/lunch_slot.dart';
import 'art/lunch_glyph.dart';

/// One school day on the parent's kid-picks screen (lunch-box ADR-0008):
/// each compartment with its options, what the child chose, or that it is
/// packed already. A tap on a compartment sets its options.
class LunchKidPicksDayCard extends StatelessWidget {
  const LunchKidPicksDayCard({
    required this.day,
    required this.choices,
    required this.childName,
    required this.onSlot,
    super.key,
  });

  final LunchDay day;
  final LunchChoices choices;
  final String childName;

  /// Null for somebody who may only look.
  final ValueChanged<LunchSlot>? onSlot;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final weekday = day.date.weekday;
    return NestCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  NestDates.weekdayName(day.date),
                  style: nest.text.title,
                ),
              ),
              if (day.isToday) const NestTag(label: LunchKidPicksCopy.today),
            ],
          ),
          const SizedBox(height: NestSpace.sm),
          for (final slot in LunchSlot.values)
            _SlotLine(
              slot: slot,
              options: [
                for (final pick in choices.optionsAt(weekday, slot)) pick.name,
              ],
              packed: day.box[slot]?.name,
              chosenByChild: _chosenName(weekday, slot),
              childName: childName,
              onTap: onSlot == null ? null : () => onSlot!(slot),
            ),
        ],
      ),
    );
  }

  /// What the child chose here, when the box still holds it.
  String? _chosenName(int weekday, LunchSlot slot) {
    final chosenId = choices.chosenAt(weekday, slot);
    final packed = day.box[slot];
    if (chosenId == null || packed?.itemId != chosenId) return null;
    return packed?.name;
  }
}

class _SlotLine extends StatelessWidget {
  const _SlotLine({
    required this.slot,
    required this.options,
    required this.packed,
    required this.chosenByChild,
    required this.childName,
    required this.onTap,
  });

  final LunchSlot slot;
  final List<String> options;
  final String? packed;
  final String? chosenByChild;
  final String childName;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final chosen = chosenByChild;
    final packed = this.packed;
    return NestListRow(
      title: LunchCopy.slotName(slot),
      subtitle: switch ((options.isEmpty, packed)) {
        (false, _) => LunchKidPicksCopy.optionsList(options),
        (true, final String _) => LunchKidPicksCopy.packedByYou,
        (true, null) => LunchKidPicksCopy.setOptions,
      },
      leading: LunchSlotTile(slot: slot, isEmpty: options.isEmpty),
      footer: options.isEmpty
          ? null
          : Align(
              alignment: AlignmentDirectional.centerStart,
              child: chosen != null
                  ? NestTag(
                      label: LunchKidPicksCopy.chose(childName, chosen),
                      tone: NestTagTone.success,
                      icon: LucideIcons.star,
                    )
                  : const NestTag(label: LunchKidPicksCopy.waiting),
            ),
      trailing: onTap == null
          ? null
          : const Icon(LucideIcons.chevronRight, size: NestSize.iconMedium),
      onTap: onTap,
    );
  }
}
