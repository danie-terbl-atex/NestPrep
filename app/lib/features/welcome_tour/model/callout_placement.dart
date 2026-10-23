import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';

/// Which side of the spotlight the callout sits on.
enum CalloutSide {
  below,
  above,

  /// Neither side has room — a target taller than the screen allows — so it
  /// sits at the foot of the screen, over the target.
  over,
}

/// Where the welcome tour's callout goes for a spotlighted component
/// (welcome-tour ADR-0002): above or below it, whichever has more room,
/// inside the safe area and clear of the gesture strip, never wider than a
/// card should be, with its pointer under the component's centre. Pure
/// arithmetic, so the edge cases are tested without a screen.
@immutable
class CalloutPlacement {
  const CalloutPlacement({
    required this.side,
    required this.left,
    required this.width,
    required this.edge,
    required this.maxHeight,
    required this.pointerX,
  });

  /// Lays the callout out for [target] inside [safe] — the screen less its
  /// system insets.
  factory CalloutPlacement.of({
    required Rect target,
    required Rect safe,
    double gap = 12,
    double gutter = 16,
    double maxWidth = 420,
    double minHeight = 160,
  }) {
    final width = math.max(0, math.min(maxWidth, safe.width - 2 * gutter));
    final shown = target.intersect(safe);
    final centreX = shown.isEmpty ? safe.center.dx : shown.center.dx;
    final left = (centreX - width / 2).clamp(
      safe.left + gutter,
      math.max(safe.left + gutter, safe.right - gutter - width),
    );
    final below = safe.bottom - (target.bottom + gap);
    final above = (target.top - gap) - safe.top;
    final pointerX = (centreX - left).clamp(
      math.min(_pointerMargin, width / 2),
      math.max(width / 2, width - _pointerMargin),
    );
    if (math.max(below, above) < minHeight) {
      return CalloutPlacement(
        side: CalloutSide.over,
        left: left.toDouble(),
        width: width.toDouble(),
        edge: safe.bottom - gutter,
        maxHeight: math.max(
          0,
          math.min(safe.height - 2 * gutter, safe.height / 2),
        ),
        pointerX: pointerX.toDouble(),
      );
    }
    final isBelow = below >= above;
    return CalloutPlacement(
      side: isBelow ? CalloutSide.below : CalloutSide.above,
      left: left.toDouble(),
      width: width.toDouble(),
      edge: isBelow ? target.bottom + gap : target.top - gap,
      maxHeight: isBelow ? below : above,
      pointerX: pointerX.toDouble(),
    );
  }

  /// How far in from the card's corners the pointer may sit.
  static const _pointerMargin = 28.0;

  final CalloutSide side;
  final double left;
  final double width;

  /// The y of the card's edge nearest the target: its top when it sits below,
  /// its bottom when it sits above or over.
  final double edge;

  /// The tallest the card may be; past it, the card scrolls.
  final double maxHeight;

  /// Where the pointer sits, measured from the card's left.
  final double pointerX;
}
