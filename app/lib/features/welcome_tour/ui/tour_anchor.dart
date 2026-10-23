import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../model/tour_target.dart';
import '../state/tour_anchor_registry.dart';

/// Marks a real component as something the welcome tour can spotlight
/// (welcome-tour ADR-0002). A screen wraps the component in one line and
/// knows nothing else about the tour: no copy, no steps, no state. Outside a
/// household shell — a screen test, the design gallery — it is just its
/// child.
class TourAnchor extends StatefulWidget {
  const TourAnchor({
    required this.target,
    required this.child,
    this.inset = EdgeInsets.zero,
    super.key,
  });

  final TourTarget target;
  final Widget child;

  /// How much of [child] is margin around the component, so the spotlight
  /// fits the component rather than its padding.
  final EdgeInsets inset;

  @override
  State<TourAnchor> createState() => _TourAnchorState();
}

class _TourAnchorState extends State<TourAnchor> {
  TourAnchorRegistry? _registry;

  @override
  void initState() {
    super.initState();
    _registry = context.read<TourAnchorRegistry?>();
    _add();
  }

  @override
  void didUpdateWidget(TourAnchor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.target == widget.target && oldWidget.inset == widget.inset) {
      return;
    }
    _registry?.remove(oldWidget.target, context);
    _add();
  }

  void _add() => _registry?.add(
    widget.target,
    TourAnchorEntry(context: context, inset: widget.inset),
  );

  @override
  void dispose() {
    _registry?.remove(widget.target, context);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
