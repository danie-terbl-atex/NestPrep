import 'package:flutter/widgets.dart';

import '../tokens/nest_motion.dart';

/// Settles [child] to 0.98 while a finger is on it (design-system ADR-0008).
/// Purely visual: the child keeps its own tap handling and semantics.
class NestPressable extends StatefulWidget {
  const NestPressable({required this.child, this.enabled = true, super.key});

  final Widget child;
  final bool enabled;

  @override
  State<NestPressable> createState() => _NestPressableState();
}

class _NestPressableState extends State<NestPressable> {
  var _down = false;

  void _set(bool down) {
    if (_down != down && mounted) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    final motion = NestMotion.of(context);
    final pressed = _down && widget.enabled && !motion.isReduced;
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: pressed ? NestMotion.pressScale : 1,
        duration: motion.quick,
        curve: NestMotion.standardCurve,
        child: widget.child,
      ),
    );
  }
}
