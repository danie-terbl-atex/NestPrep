import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/scaled_ingredients.dart';
import 'scaled_ingredient_text.dart';

/// One ingredient at the chosen scale — the amount first and strong, then
/// the name, then its note — and a tick to keep your place while you
/// gather or cook. Ticked off, it reads quieter and struck through, and the
/// circle holds a check, so the state is never only a colour (`FE-13`). The
/// whole row is the target, and a screen reader hears it as the checkbox it
/// is.
class RecipeIngredientRow extends StatelessWidget {
  const RecipeIngredientRow({
    required this.ingredient,
    required this.isTicked,
    required this.onToggle,
    super.key,
  });

  final ScaledIngredient ingredient;
  final bool isTicked;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final c = nest.colors;
    final text = ScaledIngredientText.of(ingredient);
    final ink = isTicked ? c.inkTertiary : c.ink;
    final strike = isTicked ? TextDecoration.lineThrough : null;
    return Semantics(
      checked: isTicked,
      label: RecipeCopy.ingredientLabel(text.amount, text.line),
      excludeSemantics: true,
      onTap: onToggle,
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(NestRadius.sm),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: NestSize.touchTarget),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: NestSpace.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Tick(isTicked: isTicked),
                const SizedBox(width: NestSpace.md),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        if (text.amount.isNotEmpty)
                          nestFractionSpan(
                            RecipeCopy.amountBeforeName(text.amount),
                            nest.text.bodyStrong.copyWith(
                              color: ink,
                              decoration: strike,
                            ),
                          ),
                        TextSpan(
                          text: text.line,
                          style: nest.text.body.copyWith(
                            color: ink,
                            decoration: strike,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Tick extends StatelessWidget {
  const _Tick({required this.isTicked});

  final bool isTicked;

  @override
  Widget build(BuildContext context) {
    final c = NestTheme.of(context).colors;
    return Padding(
      // Level with the first line of a body-text row.
      padding: const EdgeInsets.only(top: NestSpace.xxs),
      child: AnimatedContainer(
        duration: NestMotion.of(context).quick,
        width: NestSize.iconMedium,
        height: NestSize.iconMedium,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isTicked ? c.accentInk : Colors.transparent,
          border: Border.all(
            color: isTicked ? c.accentInk : c.outlineStrong,
            width: NestStroke.focus,
          ),
        ),
        child: isTicked
            ? Icon(LucideIcons.check, size: NestSize.iconBadge, color: c.canvas)
            : null,
      ),
    );
  }
}
