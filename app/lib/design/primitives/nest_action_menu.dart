import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../tokens/nest_motion.dart';
import '../tokens/nest_spacing.dart';
import '../tokens/nest_theme.dart';
import 'nest_button.dart';
import 'nest_rise_in.dart';

class NestActionMenuItem {
  const NestActionMenuItem({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
}

/// The floating "+" of a screen that can add more than one kind of thing: a
/// tap opens the choices above it, and the "+" turns into a close. With one
/// item it is that item's button, because a menu of one is a wasted tap.
/// A tap anywhere else closes it.
class NestActionMenu extends StatefulWidget {
  const NestActionMenu({
    required this.label,
    required this.closeLabel,
    required this.items,
    super.key,
  });

  final String label;
  final String closeLabel;
  final List<NestActionMenuItem> items;

  @override
  State<NestActionMenu> createState() => _NestActionMenuState();
}

class _NestActionMenuState extends State<NestActionMenu> {
  bool _isOpen = false;

  void _setOpen(bool isOpen) => setState(() => _isOpen = isOpen);

  void _pick(NestActionMenuItem item) {
    _setOpen(false);
    item.onPressed();
  }

  void _toggle() {
    if (widget.items.length == 1) return _pick(widget.items.single);
    _setOpen(!_isOpen);
  }

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final c = nest.colors;
    final label = _isOpen ? widget.closeLabel : widget.label;
    return TapRegion(
      onTapOutside: _isOpen ? (_) => _setOpen(false) : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (_isOpen)
            for (final (index, item) in widget.items.reversed.indexed) ...[
              NestRiseIn(
                index: index,
                offset: NestSpace.lg,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(NestRadius.pill),
                    boxShadow: nest.shadows.floating,
                  ),
                  child: NestButton(
                    label: item.label,
                    icon: item.icon,
                    variant: NestButtonVariant.outline,
                    size: NestButtonSize.medium,
                    isExpanded: false,
                    onPressed: () => _pick(item),
                  ),
                ),
              ),
              const SizedBox(height: NestSpace.md),
            ],
          Semantics(
            container: true,
            button: true,
            label: label,
            expanded: widget.items.length > 1 ? _isOpen : null,
            child: Tooltip(
              message: label,
              excludeFromSemantics: true,
              child: Material(
                color: c.accent,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: _toggle,
                  splashColor: c.accentPressed,
                  highlightColor: c.accentPressed,
                  child: SizedBox.square(
                    dimension: NestSize.controlLarge,
                    child: AnimatedRotation(
                      turns: _isOpen ? 0.125 : 0,
                      duration: NestMotion.of(context).standard,
                      curve: NestMotion.enter,
                      child: Icon(
                        LucideIcons.plus,
                        size: NestSize.iconMedium,
                        color: c.onAccent,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
