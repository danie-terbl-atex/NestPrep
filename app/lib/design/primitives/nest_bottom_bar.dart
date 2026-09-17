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

/// The floating pill navigation bar: outlined icons, the selected one in the
/// accent. Labels are read to assistive tech and shown as tooltips (`FE-13`).
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
          color: c.surfaceGlass,
          shape: StadiumBorder(side: BorderSide(color: c.outline)),
          shadows: nest.shadows.floating,
        ),
        child: SizedBox(
          height: NestSize.bottomBarHeight,
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
    final c = NestTheme.of(context).colors;
    return Semantics(
      button: true,
      selected: isSelected,
      label: item.label,
      child: Tooltip(
        message: item.label,
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: Center(
            child: AnimatedSwitcher(
              duration: NestMotion.of(context).quick,
              child: Icon(
                isSelected ? item.selectedIcon : item.icon,
                key: ValueKey(isSelected),
                size: NestSize.iconLarge,
                color: isSelected ? c.accent : c.inkSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
