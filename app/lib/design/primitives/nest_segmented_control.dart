import 'package:flutter/material.dart';

import '../tokens/nest_motion.dart';
import '../tokens/nest_spacing.dart';
import '../tokens/nest_theme.dart';

/// One choice of a segmented control: what it is called, and an optional
/// glyph beside the name.
@immutable
class NestSegment<T> {
  const NestSegment({required this.value, required this.label, this.icon});

  final T value;
  final String label;
  final IconData? icon;
}

/// Two or three views of one place, side by side in a pill track — the
/// Meals tab's *Recipes | This week* (design-system ADR-0015). The chosen
/// segment is a Guava fill with bold Ink on it, so the choice never rests on
/// colour alone (`FE-13`); each segment is its own selectable node a screen
/// reader can activate, at least the touch-target floor tall.
///
/// It holds no choice of its own: [selected] comes from whoever owns it — a
/// route, usually (`FE-07`) — and a tap is reported through [onSelect].
class NestSegmentedControl<T> extends StatelessWidget {
  const NestSegmentedControl({
    required this.segments,
    required this.selected,
    required this.onSelect,
    super.key,
  });

  final List<NestSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onSelect;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final c = nest.colors;
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: c.surface,
        shape: StadiumBorder(side: BorderSide(color: c.outline)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(NestSpace.xs),
        child: Row(
          children: [
            for (final segment in segments)
              Expanded(
                child: _Segment(
                  segment: segment,
                  isSelected: segment.value == selected,
                  onTap: () => onSelect(segment.value),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Segment<T> extends StatelessWidget {
  const _Segment({
    required this.segment,
    required this.isSelected,
    required this.onTap,
  });

  final NestSegment<T> segment;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final c = nest.colors;
    final foreground = isSelected ? c.onSecondary : c.inkSecondary;
    final icon = segment.icon;
    return Semantics(
      container: true,
      button: true,
      selected: isSelected,
      inMutuallyExclusiveGroup: true,
      label: segment.label,
      onTap: onTap,
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: NestMotion.of(context).quick,
        curve: NestMotion.standardCurve,
        decoration: ShapeDecoration(
          color: isSelected ? c.secondary : c.surface,
          shape: const StadiumBorder(),
        ),
        child: Material(
          color: Colors.transparent,
          shape: const StadiumBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: NestSize.controlSmall,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: NestSpace.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: NestSize.iconSmall, color: foreground),
                      const SizedBox(width: NestSpace.sm),
                    ],
                    // Half a phone at 200% text: the name yields rather than
                    // overflowing (`FE-14`); the node still says all of it.
                    Flexible(
                      child: Text(
                        segment.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: nest.text.label.copyWith(
                          color: foreground,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
