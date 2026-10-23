import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../model/callout_placement.dart';
import 'tour_callout_pointer.dart';

/// The callout set beside the spotlight window by [CalloutPlacement], with
/// its pointer toward the component, hidden while the window is still
/// travelling (welcome-tour ADR-0002).
class TourPlacedCallout extends StatelessWidget {
  const TourPlacedCallout({
    required this.hole,
    required this.arrival,
    required this.callout,
    this.keepClear,
    super.key,
  });

  /// Something at the foot of the screen the callout must stay above.
  final Rect? keepClear;

  final Rect? hole;

  /// The window's journey; the callout shows once it has ended.
  final Animation<double> arrival;
  final Widget? callout;

  @override
  Widget build(BuildContext context) {
    final hole = this.hole;
    final callout = this.callout;
    if (hole == null || callout == null) return const SizedBox.expand();
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final placement = CalloutPlacement.of(
          target: hole,
          safe: _clearOf(safeAreaOf(MediaQuery.of(context), size), hole),
        );
        final isBelow = placement.side == CalloutSide.below;
        final hasPointer = placement.side != CalloutSide.over;
        final pointer = Padding(
          padding: EdgeInsetsDirectional.only(
            start: math.max(0, placement.pointerX - TourCalloutPointer.size),
          ),
          child: TourCalloutPointer(pointsUp: isBelow),
        );
        return Stack(
          children: [
            Positioned(
              left: placement.left,
              width: placement.width,
              top: isBelow ? placement.edge : null,
              bottom: isBelow ? null : size.height - placement.edge,
              child: AnimatedBuilder(
                animation: arrival,
                builder: (context, child) =>
                    Opacity(opacity: arrival.isAnimating ? 0 : 1, child: child),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasPointer && isBelow) pointer,
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: math.max(
                          0,
                          placement.maxHeight - TourCalloutPointer.size,
                        ),
                      ),
                      child: callout,
                    ),
                    if (hasPointer && !isBelow) pointer,
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// The safe area, ending above [keepClear] when it sits at the foot of the
  /// screen and is not itself what is spotlighted.
  Rect _clearOf(Rect safe, Rect hole) {
    final clear = keepClear;
    if (clear == null || clear.overlaps(hole)) return safe;
    if (clear.top < safe.center.dy || clear.top >= safe.bottom) return safe;
    return Rect.fromLTRB(safe.left, safe.top, safe.right, clear.top);
  }

  /// The screen less the status bar, the notch and the gesture strip — a
  /// tap in the strip is the phone's, not the app's.
  static Rect safeAreaOf(MediaQueryData media, Size size) {
    final bottom = [
      media.padding.bottom,
      media.viewPadding.bottom,
      media.systemGestureInsets.bottom,
    ].reduce(math.max);
    return Rect.fromLTRB(
      media.padding.left,
      media.padding.top,
      size.width - media.padding.right,
      size.height - bottom,
    );
  }
}
