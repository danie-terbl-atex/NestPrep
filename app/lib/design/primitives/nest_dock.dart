import 'package:flutter/material.dart';

import '../tokens/nest_spacing.dart';
import '../tokens/nest_theme.dart';

/// A surface pinned to the foot of a page for the one thing the page is
/// there to do — a price and the button that buys. It goes in
/// `NestScaffold.bottomBar`, keeps clear of the system's own bar, and the
/// page scrolls under it. It is only ever as tall as [child]: a scaffold
/// offers its bar the whole screen, and a child that took it would cover the
/// page and its way out.
class NestDock extends StatelessWidget {
  const NestDock({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    const shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(NestRadius.xxl)),
    );
    return DecoratedBox(
      decoration: ShapeDecoration(shape: shape, shadows: nest.shadows.floating),
      child: Material(
        color: nest.colors.surface,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              NestSpace.gutter,
              NestSpace.lg,
              NestSpace.gutter,
              NestSpace.md,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [child],
            ),
          ),
        ),
      ),
    );
  }
}
