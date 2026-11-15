import 'package:flutter/material.dart';

import '../tokens/nest_motion.dart';
import '../tokens/nest_spacing.dart';
import 'nest_chip.dart';
import 'nest_segmented_control.dart';

/// More views of one place than a [NestSegmentedControl] has room for: one
/// row of chips that scrolls sideways rather than wrapping onto a second line
/// (`FE-14`). The chosen chip is brought into view, so a view opened from
/// elsewhere never starts off-screen.
class NestChipRail<T> extends StatefulWidget {
  const NestChipRail({
    required this.segments,
    required this.selected,
    required this.onSelect,
    super.key,
  });

  final List<NestSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onSelect;

  @override
  State<NestChipRail<T>> createState() => _NestChipRailState<T>();
}

class _NestChipRailState<T> extends State<NestChipRail<T>> {
  final _chips = <T, GlobalKey>{};

  @override
  void initState() {
    super.initState();
    _reveal();
  }

  @override
  void didUpdateWidget(NestChipRail<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected != widget.selected) _reveal();
  }

  void _reveal() => WidgetsBinding.instance.addPostFrameCallback((_) {
    final chip = _chips[widget.selected]?.currentContext;
    if (!mounted || chip == null) return;
    Scrollable.ensureVisible(
      chip,
      alignment: 0.5,
      duration: NestMotion.of(context).quick,
      curve: NestMotion.standardCurve,
    );
  });

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    clipBehavior: Clip.none,
    child: Row(
      children: [
        for (final (index, segment) in widget.segments.indexed)
          Padding(
            key: _chips.putIfAbsent(segment.value, GlobalKey.new),
            padding: EdgeInsetsDirectional.only(
              start: index == 0 ? 0 : NestSpace.sm,
            ),
            child: Semantics(
              hint: segment.hint,
              child: NestChip(
                label: segment.label,
                icon: segment.icon,
                isSelected: segment.value == widget.selected,
                onTap: () => widget.onSelect(segment.value),
              ),
            ),
          ),
      ],
    ),
  );
}
