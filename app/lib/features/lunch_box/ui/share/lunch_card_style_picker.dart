import 'package:flutter/material.dart';

import '../../../../design/nest_kit.dart';
import '../../../../shared/copy/app_copy.dart';
import '../../model/lunch_card_style.dart';
import '../card/lunch_card_palette.dart';

/// The four card looks as swatches, each its own ground colour with its
/// name under it; the chosen one ringed in the teal that selects
/// (design-system ADR-0003) and ticked, so colour is never the only signal.
class LunchCardStylePicker extends StatelessWidget {
  const LunchCardStylePicker({
    required this.selected,
    required this.onSelect,
    super.key,
  });

  final LunchCardStyle selected;
  final ValueChanged<LunchCardStyle> onSelect;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: NestSpace.md,
    runSpacing: NestSpace.sm,
    children: [
      for (final style in LunchCardStyle.values)
        _Swatch(
          style: style,
          isSelected: style == selected,
          onTap: () => onSelect(style),
        ),
    ],
  );
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.style,
    required this.isSelected,
    required this.onTap,
  });

  final LunchCardStyle style;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final palette = LunchCardPalette.of(style);
    final name = LunchShareCopy.styleName(style);
    return Semantics(
      container: true,
      button: true,
      selected: isSelected,
      label: name,
      onTap: onTap,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(NestRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(NestSpace.xs),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: palette.ground,
                  ),
                  border: Border.all(
                    color: isSelected
                        ? nest.colors.secondary
                        : nest.colors.outlineStrong,
                    width: isSelected ? NestStroke.focus * 2 : NestStroke.focus,
                  ),
                ),
                child: SizedBox.square(
                  dimension: NestSize.touchTarget,
                  child: isSelected
                      ? Icon(
                          LucideIcons.check,
                          size: NestSize.iconMedium,
                          color: palette.theme.colors.ink,
                        )
                      : null,
                ),
              ),
              const SizedBox(height: NestSpace.xs),
              Text(
                name,
                style: nest.text.caption.copyWith(
                  color: isSelected
                      ? nest.colors.secondaryInk
                      : nest.colors.inkSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
