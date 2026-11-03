import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/lunch_slot.dart';
import '../state/lunch_variety_choice.dart';

/// Which of [slots] keep the same all week (lunch-box ADR-0028): one chip
/// per compartment, on in *Plan my week*'s brief and *Fill the week*'s
/// review alike. The screen around it watches [choice] through its own
/// controller.
class LunchVarietySection extends StatelessWidget {
  const LunchVarietySection({
    required this.choice,
    required this.slots,
    super.key,
  });

  final LunchVarietyChoice choice;
  final Set<LunchSlot> slots;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final variety = choice.variety;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const NestSectionHeader(title: LunchVarietyCopy.header),
        const SizedBox(height: NestSpace.xs),
        Text(LunchVarietyCopy.body, style: nest.text.bodySecondary),
        const SizedBox(height: NestSpace.sm),
        Wrap(
          spacing: NestSpace.sm,
          runSpacing: NestSpace.sm,
          children: [
            for (final slot in LunchSlot.values)
              if (slots.contains(slot))
                NestChip(
                  key: ValueKey('variety-${slot.name}'),
                  label: LunchCopy.slotName(slot),
                  isSelected: variety.keepsSame(slot),
                  icon: variety.keepsSame(slot)
                      ? LucideIcons.repeat
                      : LucideIcons.shuffle,
                  onTap: () => choice.toggle(slot),
                ),
          ],
        ),
      ],
    );
  }
}
