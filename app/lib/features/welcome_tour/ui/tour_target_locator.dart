import 'package:flutter/widgets.dart';

import '../model/tour_target.dart';
import '../state/tour_anchor_registry.dart';

/// What the locator found: which target, and its anchor.
@immutable
class TourFound {
  const TourFound(this.target, this.entry);

  final TourTarget target;
  final TourAnchorEntry entry;
}

/// Finds a tour stop's component on the screen that has just been opened
/// (welcome-tour ADR-0002) — patiently, but never for ever.
///
/// It waits for the page to arrive, then for any of the candidates, best
/// first. A list builds only what is near the screen, so a component further
/// down may not exist yet: once the page has had time to load, the locator
/// scrolls the page's own list down a screen at a time until a candidate is
/// built or the list ends. Found, the component is scrolled into view; not
/// found within [patience], the answer is null and the stop is skipped.
final class TourTargetLocator {
  TourTargetLocator(this._registry);

  final TourAnchorRegistry _registry;

  static const _tick = Duration(milliseconds: 50);

  /// How long the page is given to load before the locator starts scrolling.
  static const _settle = Duration(milliseconds: 700);

  /// How long a page that has arrived, with no list to scroll, is given.
  static const _givingUp = Duration(seconds: 2);

  Future<TourFound?> locate(
    List<TourTarget> candidates, {
    required Duration patience,
    required Duration scrollDuration,
    required bool Function() isStale,
  }) async {
    // Counted in ticks rather than read off the clock, so a widget test's
    // fake time drives it exactly as a phone's real time does.
    var waited = Duration.zero;
    var hasWrapped = false;
    // Held for the whole search: the anchor it was found through may scroll
    // out of what the list builds.
    ScrollPosition? list;
    while (!isStale() && waited < patience) {
      final found = _first(candidates);
      if (found != null) {
        await _bringIntoView(found.entry, scrollDuration);
        return isStale() ? null : found;
      }
      if (waited >= _settle) {
        list = _pageScrollPosition(list);
        final scrolled = _scrollFurther(list, fromTop: !hasWrapped);
        // A step back may want something above where the list was left, so
        // the end of the list sends it once to the top to look again.
        if (scrolled == _Scrolled.wrapped) hasWrapped = true;
        if (scrolled == _Scrolled.atEnd && waited >= _settle * 2) {
          // The page has loaded, its list has ended, and nothing is there.
          return null;
        }
        if (scrolled == _Scrolled.noList &&
            waited >= _givingUp &&
            _registry.showing.isNotEmpty) {
          // The page is plainly there — its own anchors are — with no list
          // to look further down: whatever it shows instead (a locked or
          // empty state) is not this stop's component.
          return null;
        }
      }
      WidgetsBinding.instance.scheduleFrame();
      await Future<void>.delayed(_tick);
      waited += _tick;
    }
    return null;
  }

  TourFound? _first(List<TourTarget> candidates) {
    for (final target in candidates) {
      final entry = _registry.find(target);
      if (entry != null) return TourFound(target, entry);
    }
    return null;
  }

  /// Moves the page's list one screen further down — or, at its end and
  /// allowed [fromTop], back to its top.
  _Scrolled _scrollFurther(ScrollPosition? position, {required bool fromTop}) {
    if (position == null || !position.hasContentDimensions) {
      return _Scrolled.noList;
    }
    if (position.pixels >= position.maxScrollExtent) {
      if (!fromTop || position.pixels <= position.minScrollExtent) {
        return _Scrolled.atEnd;
      }
      position.jumpTo(position.minScrollExtent);
      return _Scrolled.wrapped;
    }
    position.jumpTo(
      (position.pixels + position.viewportDimension * 0.8).clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      ),
    );
    return _Scrolled.moved;
  }

  /// The vertical list some showing anchor sits in — the page's own — or
  /// the one already found while it is still on screen.
  ScrollPosition? _pageScrollPosition(ScrollPosition? found) {
    if (found != null && found.hasPixels && _isOnScreen(found)) return found;
    for (final entry in _registry.showing) {
      final scrollable = Scrollable.maybeOf(entry.context);
      if (scrollable != null &&
          scrollable.axisDirection == AxisDirection.down) {
        return scrollable.position;
      }
    }
    return null;
  }

  static bool _isOnScreen(ScrollPosition position) {
    final context = position.context.notificationContext;
    if (context == null || !context.mounted) return false;
    return ModalRoute.of(context)?.isCurrent ?? true;
  }

  Future<void> _bringIntoView(TourAnchorEntry entry, Duration duration) async {
    if (!entry.context.mounted) return;
    if (Scrollable.maybeOf(entry.context) == null) return;
    await Scrollable.ensureVisible(
      entry.context,
      alignment: 0.25,
      duration: duration,
    );
  }
}

enum _Scrolled { moved, wrapped, atEnd, noList }
