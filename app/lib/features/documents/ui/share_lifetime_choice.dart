import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/share_lifetime.dart';

/// How long a link works: the fixed lengths, and — while a nanny-hub shift is
/// on — until it ends (documents ADR-0006). Chips, so the choice is a tap and
/// its state is a word and a tick, never a colour alone (`FE-13`).
class ShareLifetimeChoice extends StatelessWidget {
  const ShareLifetimeChoice({
    required this.chosen,
    required this.shiftOptions,
    required this.onChosen,
    super.key,
  });

  final ShareLifetime chosen;
  final List<ShiftLifetime> shiftOptions;
  final ValueChanged<ShareLifetime> onChosen;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const NestSectionHeader(title: ShareLinkCopy.lifetimeLabel),
        const SizedBox(height: NestSpace.sm),
        Wrap(
          spacing: NestSpace.sm,
          runSpacing: NestSpace.sm,
          children: [
            for (final shift in shiftOptions)
              NestChip(
                key: ValueKey('shift-${shift.shiftId}'),
                label: ShareLinkCopy.untilShiftEnds(shift.carerName),
                icon: Icons.child_care_outlined,
                isSelected: chosen == shift,
                onTap: () => onChosen(shift),
              ),
            for (final hours in ShareLifetime.hourOptions)
              NestChip(
                key: ValueKey('hours-$hours'),
                label: ShareLinkCopy.hours(hours),
                isSelected: chosen == HoursLifetime(hours),
                onTap: () => onChosen(HoursLifetime(hours)),
              ),
          ],
        ),
        if (chosen is ShiftLifetime) ...[
          const SizedBox(height: NestSpace.sm),
          Text(
            ShareLinkCopy.shiftNote,
            style: nest.text.caption.copyWith(color: nest.colors.inkSecondary),
          ),
        ],
      ],
    );
  }
}
