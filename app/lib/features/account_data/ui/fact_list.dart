import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';

/// A short titled list of plain facts — what an export holds, what deleting
/// removes, what stays. Each line is its own sentence for a screen reader;
/// the dot beside it is decoration (`FE-13`).
class FactList extends StatelessWidget {
  const FactList({
    required this.title,
    required this.facts,
    this.icon = LucideIcons.circleCheck,
    super.key,
  });

  final String title;
  final List<String> facts;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(header: true, child: Text(title, style: nest.text.title)),
        const SizedBox(height: NestSpace.sm),
        for (final fact in facts)
          Padding(
            padding: const EdgeInsets.only(bottom: NestSpace.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(
                  child: Icon(
                    icon,
                    size: NestSize.iconSmall,
                    color: nest.colors.inkSecondary,
                  ),
                ),
                const SizedBox(width: NestSpace.sm),
                Expanded(child: Text(fact, style: nest.text.body)),
              ],
            ),
          ),
      ],
    );
  }
}
