import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../lunch_box/model/lunch_slot.dart';
import '../model/packing_preference.dart';
import '../state/plan_week_controller.dart';

/// The brief's packing choices: which compartments get filled — the last one
/// on cannot be switched off — and how the parent likes to pack, any number
/// or none.
class PlanWeekPackingSection extends StatelessWidget {
  const PlanWeekPackingSection({super.key});

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final packing = context.watch<PlanWeekController>().packing;
    final slots = packing.slots;
    final preferences = packing.preferences;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const NestSectionHeader(title: PlanWeekCopy.slotsHeader),
        const SizedBox(height: NestSpace.xs),
        Text(PlanWeekCopy.slotsBody, style: nest.text.bodySecondary),
        const SizedBox(height: NestSpace.sm),
        _Chips(
          children: [
            for (final slot in LunchSlot.values)
              NestChip(
                key: ValueKey('plan-slot-${slot.name}'),
                label: LunchCopy.slotName(slot),
                isSelected: slots.contains(slot),
                icon: slots.contains(slot)
                    ? LucideIcons.check
                    : LucideIcons.plus,
                onTap: packing.isLastSlot(slot)
                    ? null
                    : () => packing.toggleSlot(slot),
              ),
          ],
        ),
        const SizedBox(height: NestSpace.xl),
        const NestSectionHeader(title: PlanWeekCopy.packingHeader),
        const SizedBox(height: NestSpace.xs),
        Text(PlanWeekCopy.packingBody, style: nest.text.bodySecondary),
        const SizedBox(height: NestSpace.sm),
        _Chips(
          children: [
            for (final preference in PackingPreference.values)
              NestChip(
                key: ValueKey('plan-packing-${preference.name}'),
                label: PlanWeekCopy.packingPreference(preference),
                isSelected: preferences.contains(preference),
                onTap: () => packing.togglePreference(preference),
              ),
          ],
        ),
      ],
    );
  }
}

class _Chips extends StatelessWidget {
  const _Chips({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) =>
      Wrap(spacing: NestSpace.sm, runSpacing: NestSpace.sm, children: children);
}
