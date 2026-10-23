import 'package:flutter/widgets.dart';

import '../model/tour_target.dart';

/// One placed anchor: where it is in the tree, and how much of it is margin
/// rather than the component.
@immutable
class TourAnchorEntry {
  const TourAnchorEntry({required this.context, required this.inset});

  final BuildContext context;
  final EdgeInsets inset;

  /// On screen in the route that is showing, laid out, attached and with
  /// some size — a component that hides itself as an empty box is not
  /// there.
  bool get isShowing {
    if (!context.mounted) return false;
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) return false;
    final box = context.findRenderObject();
    return box is RenderBox && box.attached && box.hasSize && !box.size.isEmpty;
  }
}

/// Every `TourAnchor` on screen, by target (welcome-tour ADR-0002). Held by
/// the household shell and read by the tour layer; the anchors only add and
/// remove themselves.
///
/// One target may be placed on several screens at once while a route
/// changes — the bar is on every tab — so the most recently placed one that
/// is showing wins.
final class TourAnchorRegistry {
  final _entries = <TourTarget, List<TourAnchorEntry>>{};

  void add(TourTarget target, TourAnchorEntry entry) =>
      (_entries[target] ??= []).add(entry);

  void remove(TourTarget target, BuildContext context) =>
      _entries[target]?.removeWhere((entry) => entry.context == context);

  /// The showing anchor for [target], if there is one.
  TourAnchorEntry? find(TourTarget target) =>
      _entries[target]?.reversed.where((entry) => entry.isShowing).firstOrNull;

  /// Every showing anchor — for finding the page's scrollable.
  Iterable<TourAnchorEntry> get showing => [
    for (final entries in _entries.values)
      for (final entry in entries)
        if (entry.isShowing) entry,
  ];
}
