import 'package:flutter/material.dart';

/// The strip along the leading edge where an iPhone's swipe back begins, kept
/// clear of whatever lies under it. A map or a pager that reaches the edge of
/// the screen would otherwise take that drag for itself and the page could
/// not be swiped away. A child of the [Stack] that holds the map or pager,
/// placed after it. It takes no room and does nothing on Android.
class NestBackSwipeEdge extends StatelessWidget {
  const NestBackSwipeEdge({super.key});

  static const double width = 20;

  @override
  Widget build(BuildContext context) => PositionedDirectional(
    start: 0,
    top: 0,
    bottom: 0,
    width: Theme.of(context).platform == TargetPlatform.iOS ? width : 0,
    child: const AbsorbPointer(child: SizedBox.expand()),
  );
}
