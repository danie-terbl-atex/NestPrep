import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/points_copy.dart';
import '../model/reward.dart';
import 'reward_icon_glyph.dart';

/// The picture a reward wears, chosen from the fixed set (todos ADR-0003).
/// Each is a labelled, selectable button of at least the touch target; the
/// chosen one is outlined and said to be selected, never shown by colour
/// alone (`FE-13`).
class RewardIconPicker extends StatelessWidget {
  const RewardIconPicker({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final RewardIcon selected;
  final ValueChanged<RewardIcon> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = NestTheme.of(context).colors;
    return Wrap(
      spacing: NestSpace.sm,
      runSpacing: NestSpace.sm,
      children: [
        for (final icon in RewardIcon.values)
          Semantics(
            button: true,
            selected: icon == selected,
            label: PointsCopy.iconName(icon),
            excludeSemantics: true,
            child: InkWell(
              key: ValueKey('reward-icon-${icon.name}'),
              borderRadius: BorderRadius.circular(NestRadius.md),
              onTap: () => onChanged(icon),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(NestRadius.md),
                  border: Border.all(
                    color: icon == selected ? c.accent : c.surface,
                    width: NestStroke.focus,
                  ),
                ),
                child: NestIconTile(icon: icon.glyph, tint: icon.tint),
              ),
            ),
          ),
      ],
    );
  }
}
