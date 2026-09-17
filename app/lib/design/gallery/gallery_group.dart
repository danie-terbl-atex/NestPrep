import 'package:flutter/material.dart';

import '../nest_kit.dart';

/// A titled group in the gallery with its children stacked and spaced.
class GalleryGroup extends StatelessWidget {
  const GalleryGroup({required this.title, required this.children, super.key});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: NestSpace.xxxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title.toUpperCase(),
            style: nest.text.caption.copyWith(letterSpacing: 1.2),
          ),
          const SizedBox(height: NestSpace.md),
          for (final child in children) ...[
            child,
            const SizedBox(height: NestSpace.md),
          ],
        ],
      ),
    );
  }
}
