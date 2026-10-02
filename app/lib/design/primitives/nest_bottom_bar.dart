import 'package:flutter/material.dart';

import '../tokens/nest_motion.dart';
import '../tokens/nest_spacing.dart';
import '../tokens/nest_theme.dart';

@immutable
class NestBottomBarItem {
  const NestBottomBarItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

/// The floating Ink bar: an icon over its name for every tab, and the one you
/// are on carried by a Guava pill and a bolder name, not by colour alone
/// (design-system ADR-0008, ADR-0009, `FE-13`).
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
          color: c.chrome,
          shape: const StadiumBorder(),
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
    final ink = isSelected ? c.onChrome : c.onChromeMuted;
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
                curve: NestMotion.standardCurve,
                decoration: BoxDecoration(
                  color: isSelected ? c.secondary : Colors.transparent,
                  borderRadius: BorderRadius.circular(NestRadius.pill),
                ),
                child: Icon(
                  item.icon,
                  size: NestSize.iconMedium,
                  color: isSelected ? c.onSecondary : ink,
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
