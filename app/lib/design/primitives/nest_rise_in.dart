import 'package:flutter/widgets.dart';

import '../tokens/nest_motion.dart';
import '../tokens/nest_spacing.dart';

/// Brings one thing onto a screen: it fades up from a little below where it
/// belongs, [index] steps after the thing before it.
///
/// It runs **once** and stops. Motion here explains an arrival, and an arrival
/// is over (`FE-15`); nothing in this app animates forever, so every screen
/// settles, a test can wait for it, and a phone left on the sign-in screen is
/// not burning a core on decoration.
///
/// The stagger is an interval inside one controller rather than a delayed
/// callback, so there is never a pending timer outliving the widget.
///
/// Under reduce-motion every duration is zero, so the child is simply in place
/// on the first frame — nothing here checks for that.
class NestRiseIn extends StatefulWidget {
  const NestRiseIn({
    required this.child,
    this.index = 0,
    this.offset = NestSpace.xxl,
    super.key,
  });

  final Widget child;

  /// Position in the group. Step 0 leaves immediately; each later step waits
  /// one [NestMotion.stagger] longer, so a column arrives top-down.
  final int index;

  /// How far below its resting place the child starts.
  final double offset;

  @override
  State<NestRiseIn> createState() => _NestRiseInState();
}

class _NestRiseInState extends State<NestRiseIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);
  late Animation<double> _progress = kAlwaysCompleteAnimation;
  bool _hasStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasStarted) return;
    _hasStarted = true;

    final motion = NestMotion.of(context);
    final delay = motion.stagger * widget.index;
    final total = delay + motion.standard;
    if (total == Duration.zero) return;

    _controller.duration = total;
    _progress = CurvedAnimation(
      parent: _controller,
      curve: Interval(
        delay.inMicroseconds / total.inMicroseconds,
        1,
        curve: NestMotion.enter,
      ),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _progress,
    // The shift goes **outside** the fade, not inside it. The other way round
    // a control cannot be tapped while it arrives: the hit test stops at the
    // faded box and never reaches the shifted child, so a quick thumb on the
    // sign-in button lands on nothing. Motion does not block input (`FE-15`),
    // and `nest_rise_in_test.dart` taps mid-entrance to keep it that way.
    builder: (context, child) => Transform.translate(
      offset: Offset(0, widget.offset * (1 - _progress.value)),
      child: Opacity(opacity: _progress.value, child: child),
    ),
    child: widget.child,
  );
}
