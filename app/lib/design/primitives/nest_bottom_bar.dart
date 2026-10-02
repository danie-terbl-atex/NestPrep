import 'package:flutter/material.dart';

import '../tokens/nest_motion.dart';
import '../tokens/nest_spacing.dart';
import '../tokens/nest_theme.dart';

@immutable
class NestBottomBarItem {
  const NestBottomBarItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// The floating pill navigation bar: an icon over its name for every tab, and
/// the one you are on carried by a tonal teal pill as well as by colour —
/// where you are is state, not an action (ADR-0003). The names are on screen,
/// not only in a tooltip: an icon nobody can name is a tab nobody finds
/// (design-system ADR-0005, `FE-13`).
class NestBottomBar extends StatelessWidget {
  const NestBottomBar({
    required this.items,
    required this.selectedIndex,
    required this.onSelect,
    super.key,
  });

  final List<NestBottomBarItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final c = nest.colors;
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(
        NestSpace.gutter,
        0,
        NestSpace.gutter,
        NestSpace.lg,
      ),
      child: DecoratedBox(
        decoration: ShapeDecoration(
          // Opaque, not glass: with names in it, a list scrolling under a
          // translucent bar shows through the words (design-system ADR-0005).
          color: c.surface,
          shape: StadiumBorder(side: BorderSide(color: c.outline)),
          shadows: nest.shadows.floating,
        ),
        // A floor, not a height: the names grow with the text setting, and
        // the bar grows with them rather than clipping them (`FE-14`).
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: NestSize.bottomBarHeight,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: NestSpace.sm),
            child: Row(
              children: [
                for (var index = 0; index < items.length; index++)
                  Expanded(
                    child: _BarButton(
                      item: items[index],
                      isSelected: index == selectedIndex,
                      onTap: () => onSelect(index),
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

class _BarButton extends StatelessWidget {
  const _BarButton({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final NestBottomBarItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final c = nest.colors;
    final motion = NestMotion.of(context);
    final ink = isSelected ? c.secondaryInk : c.inkSecondary;
    return Semantics(
      button: true,
      selected: isSelected,
      label: item.label,
      // The icon and the name below it are one control to a screen reader;
      // excluding the children drops the ink well's tap, so the node carries
      // it itself.
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NestRadius.lg),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: NestSpace.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: motion.quick,
                width: NestSize.barIndicatorWidth,
                height: NestSize.barIndicatorHeight,
                decoration: BoxDecoration(
                  color: isSelected ? c.secondarySoft : Colors.transparent,
                  borderRadius: BorderRadius.circular(NestRadius.pill),
                ),
                child: Icon(
                  isSelected ? item.selectedIcon : item.icon,
                  size: NestSize.iconMedium,
                  color: ink,
                ),
              ),
              const SizedBox(height: NestSpace.xs),
              // Shrinks rather than wraps or clips when five names meet a
              // large text setting on a narrow phone.
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  item.label,
                  maxLines: 1,
                  style: nest.text.caption.copyWith(
                    color: ink,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
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
