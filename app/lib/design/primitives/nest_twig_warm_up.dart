import 'dart:async';

import 'package:flutter/widgets.dart';

import '../tokens/nest_imagery.dart';

/// Decodes Twig's poses ahead of the screen that will show them, so a loader
/// or a celebration that swaps in half-way through a flow has its picture
/// ready on its first frame rather than popping in a frame later
/// (design-system ADR-0012, `FE-18`).
///
/// Wrap a flow's body in it once; it draws nothing of its own.
class NestTwigWarmUp extends StatefulWidget {
  const NestTwigWarmUp({
    required this.child,
    this.poses = NestTwigPose.values,
    super.key,
  });

  final Widget child;
  final List<NestTwigPose> poses;

  @override
  State<NestTwigWarmUp> createState() => _NestTwigWarmUpState();
}

class _NestTwigWarmUpState extends State<NestTwigWarmUp> {
  var _isWarm = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isWarm) return;
    _isWarm = true;
    for (final pose in widget.poses) {
      // A pose that fails to decode is reported by precacheImage itself, and
      // the image draws nothing in its held box: nothing here to add.
      unawaited(precacheImage(AssetImage(pose.asset), context));
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
