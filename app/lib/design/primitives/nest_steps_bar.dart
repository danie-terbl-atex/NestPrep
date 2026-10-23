import 'package:flutter/material.dart';

import '../tokens/nest_motion.dart';
import '../tokens/nest_spacing.dart';
import '../tokens/nest_theme.dart';

/// Where a guided flow is: a segment per step, filled up to the one showing,
/// and [label] — the step in words, which the caller writes ("Step 2 of 3:
/// Review"). The words carry it and the bar is the glance, so a screen
/// reader hears [label] alone (`FE-13`).
class NestStepsBar extends StatelessWidget {
  const NestStepsBar({
    required this.count,
    required this.index,
    required this.label,
    super.key,
  }) : assert(count > 0 && index >= 0 && index < count);

  /// How many steps the flow has.
  final int count;

  /// The step showing, from zero.
  final int index;
  final String label;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              for (var each = 0; each < count; each++) ...[
                if (each > 0) const SizedBox(width: NestSpace.xs),
                Expanded(
                  child: AnimatedContainer(
                    duration: NestMotion.of(context).standard,
                    height: NestSpace.xs,
                    decoration: BoxDecoration(
                      color: each <= index
                          ? nest.colors.accent
                          : nest.colors.surfaceTint,
                      borderRadius: BorderRadius.circular(NestRadius.pill),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: NestSpace.sm),
          Text(label, style: nest.text.caption),
        ],
      ),
    );
  }
}
