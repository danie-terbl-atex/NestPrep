import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';

/// One step of the method, set to be read from beside the stove: its number
/// in a Butter disc, the words a size up from body text with room between
/// lines. Tapping it marks it done — the disc takes a check and the words go
/// quiet — so a cook who looked away finds their place (`FE-13`: a check
/// and a colour, never the colour alone).
class RecipeStepRow extends StatelessWidget {
  const RecipeStepRow({
    required this.number,
    required this.step,
    required this.isDone,
    required this.onToggle,
    super.key,
  });

  final int number;
  final String step;
  final bool isDone;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final c = nest.colors;
    return Semantics(
      checked: isDone,
      label: RecipeCopy.stepLabel(number, step),
      excludeSemantics: true,
      onTap: onToggle,
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(NestRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: NestSpace.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: NestMotion.of(context).quick,
                width: NestSize.logoMedium,
                height: NestSize.logoMedium,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone ? c.accentInk : c.tileButter,
                ),
                child: isDone
                    ? Icon(
                        LucideIcons.check,
                        size: NestSize.iconSmall,
                        color: c.canvas,
                      )
                    // The disc is a fixed size; at a large text setting the
                    // number shrinks into it rather than spilling (`FE-14`).
                    : FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '$number',
                          style: nest.text.label.copyWith(
                            color: c.ink,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: NestSpace.lg),
              Expanded(
                child: Text(
                  step,
                  style: nest.text.reading.copyWith(
                    color: isDone ? c.inkTertiary : c.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
