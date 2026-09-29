import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';

/// A step's place in the checklist, in a soft circle — or a tick once it is
/// done. The number is read out as part of the step it sits beside.
class StepNumber extends StatelessWidget {
  const StepNumber({
    required this.number,
    this.isDone = false,
    this.size = NestSize.avatarSmall,
    super.key,
  });

  final int number;
  final bool isDone;
  final double size;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final motion = NestMotion.of(context);
    return ExcludeSemantics(
      child: AnimatedContainer(
        duration: motion.quick,
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDone ? nest.colors.success : nest.colors.accentSoft,
        ),
        child: isDone
            ? Icon(Icons.check, size: size * 0.6, color: nest.colors.onAccent)
            : Text(
                '$number',
                style: nest.text.label.copyWith(color: nest.colors.accentInk),
              ),
      ),
    );
  }
}
