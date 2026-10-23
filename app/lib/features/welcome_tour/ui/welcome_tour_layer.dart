import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/household_route.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/copy/tour_copy.dart';
import '../../accounts/data/account_repository.dart';
import '../../accounts/state/session_controller.dart';
import '../../household/model/household_view.dart';
import '../model/tour_place.dart';
import '../model/tour_target.dart';
import '../state/tour_anchor_registry.dart';
import '../state/tour_controller.dart';
import '../state/tour_seen_recorder.dart';
import 'tour_callout.dart';
import 'tour_spotlight.dart';
import 'tour_target_locator.dart';

/// The welcome tour over the real app (welcome-tour ADR-0002): in the
/// household shell, above the page and its bar. For each stop it opens the
/// tab the stop needs, finds the component, scrolls it into view and
/// spotlights it; a stop whose component never appears is dropped rather
/// than pointed at nothing. Ending — finished or skipped — records the tour
/// on the account and lands on Today, or the lunch board.
class WelcomeTourLayer extends StatefulWidget {
  const WelcomeTourLayer({
    required this.location,
    required this.child,
    super.key,
  });

  /// Where the router is.
  final String location;
  final Widget child;

  /// How long a stop's component is waited for, all told.
  static const patience = Duration(seconds: 4);

  /// Breathing room between a component and the window's edge.
  static const windowPadding = NestSpace.sm;

  @override
  State<WelcomeTourLayer> createState() => _WelcomeTourLayerState();
}

class _WelcomeTourLayerState extends State<WelcomeTourLayer>
    with WidgetsBindingObserver {
  late final TourController _tour = context.read<TourController>();
  late final TourAnchorRegistry _registry = context.read<TourAnchorRegistry>();
  late final TourTargetLocator _locator = TourTargetLocator(_registry);
  final _layerKey = GlobalKey();

  /// Bumped on every step, so a search a newer step overtook stands down.
  int _generation = 0;
  TourFound? _found;
  Rect? _hole;
  bool _wasActive = false;
  bool _isRemeasuring = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tour.addListener(_onTour);
    if (_tour.isActive) _onTour();
  }

  @override
  void dispose() {
    _tour.removeListener(_onTour);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() => _remeasureSoon();

  void _onTour() {
    if (_tour.isActive) {
      _wasActive = true;
      _show(++_generation);
    } else if (_wasActive) {
      _wasActive = false;
      _generation++;
      _end(_tour.lastEnd ?? TourEnd.skipped);
    }
  }

  String _pathOf(TourPlace place) => HouseholdRoute.pathFor(
    context.read<HouseholdView>().household.id,
    place.tab,
  );

  Future<void> _show(int generation) async {
    final stop = _tour.current;
    if (stop == null) return;
    setState(() {
      _found = null;
      _hole = null;
    });
    final path = _pathOf(stop.place);
    if (widget.location != path) GoRouter.of(context).go(path);
    final found = await _locator.locate(
      stop.candidates,
      patience: WelcomeTourLayer.patience,
      scrollDuration: NestMotion.of(context).standard,
      isStale: () => !mounted || generation != _generation,
    );
    if (!mounted || generation != _generation) return;
    if (found == null) return _tour.dropCurrent();
    setState(() {
      _found = found;
      _hole = _measure(found);
    });
    _remeasureSoon();
  }

  void _end(TourEnd end) {
    setState(() {
      _found = null;
      _hole = null;
    });
    final session = context.read<SessionController>();
    TourSeenRecorder(
      accountRepository: context.read<AccountRepository>(),
      signedInUid: () => session.uidOrEmpty,
    ).markSeen();
    for (final entry in _registry.showing) {
      final position = Scrollable.maybeOf(entry.context)?.position;
      if (position != null && position.hasContentDimensions) {
        position.jumpTo(position.minScrollExtent);
      }
    }
    final place = end == TourEnd.finished ? _tour.finishOn : TourPlace.today;
    GoRouter.of(context).go(_pathOf(place));
  }

  /// The component's box in this layer's coordinates, less its margin, plus
  /// a little room.
  Rect? _measure(TourFound found) {
    final box = found.entry.context.findRenderObject();
    final layer = _layerKey.currentContext?.findRenderObject();
    if (box is! RenderBox || layer is! RenderBox || !box.attached) return null;
    if (!box.hasSize || !layer.hasSize) return null;
    final origin = box.localToGlobal(Offset.zero, ancestor: layer);
    final inset = found.entry.inset;
    return Rect.fromLTRB(
      origin.dx + inset.left,
      origin.dy + inset.top,
      origin.dx + box.size.width - inset.right,
      origin.dy + box.size.height - inset.bottom,
    ).inflate(WelcomeTourLayer.windowPadding);
  }

  /// Where the bar is, so a callout keeps clear of it.
  Rect? _barRect() {
    final bar = _registry.find(TourTarget.tabBar);
    return bar == null ? null : _measure(TourFound(TourTarget.tabBar, bar));
  }

  /// Measures again after the next frame, and keeps doing so while the
  /// component is still moving — a list settling, a page sliding in, the
  /// phone turning — then stops.
  void _remeasureSoon() {
    if (_isRemeasuring || _found == null) return;
    _isRemeasuring = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isRemeasuring = false;
      final found = _found;
      if (!mounted || found == null) return;
      final rect = _measure(found);
      if (rect == null || rect == _hole) return;
      setState(() => _hole = rect);
      _remeasureSoon();
    });
  }

  @override
  Widget build(BuildContext context) {
    final page = NotificationListener<Notification>(
      onNotification: (notification) {
        if (notification is ScrollNotification ||
            notification is ScrollMetricsNotification ||
            notification is SizeChangedLayoutNotification) {
          _remeasureSoon();
        }
        return false;
      },
      child: widget.child,
    );
    final found = _found;
    final stop = _tour.current;
    return Stack(
      key: _layerKey,
      children: [
        page,
        if (stop != null)
          Positioned.fill(
            child: BackButtonListener(
              onBackButtonPressed: () async {
                _tour.backOrSkip();
                return true;
              },
              child: BlockSemantics(
                child: TourSpotlight(
                  hole: _hole,
                  keepClear: _barRect(),
                  onTapWindow: _tour.next,
                  callout: found == null
                      ? null
                      : FocusScope(
                          autofocus: true,
                          child: Semantics(
                            liveRegion: true,
                            container: true,
                            child: TourCallout(
                              key: ValueKey('${_tour.index}-${found.target}'),
                              stop: stop,
                              shown: found.target,
                              number: _tour.index + 1,
                              count: _tour.count,
                              nextLabel: _nextLabel(),
                              actions: TourCalloutActions(
                                onNext: _tour.next,
                                onBack: _tour.isFirst ? null : _tour.back,
                                onSkip: _tour.skip,
                              ),
                            ),
                          ),
                        ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _nextLabel() => !_tour.isLast
      ? TourCopy.next
      : _tour.finishOn == TourPlace.lunch
      ? TourCopy.planFirstLunch
      : TourCopy.done;
}
