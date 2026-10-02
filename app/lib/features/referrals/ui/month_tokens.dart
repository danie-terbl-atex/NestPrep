import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';

/// One small token per free month the year allows, filled for each one
/// earned — the yearly limit at a glance. Decoration: the sentence beside it
/// says the numbers, so a screen reader is not told twice (`FE-13`), and a
/// filled token differs by its icon as well as its colour.
class MonthTokens extends StatelessWidget {
  const MonthTokens({required this.earned, required this.cap, super.key});

  final int earned;
  final int cap;

  @override
  Widget build(BuildContext context) {
    final colors = NestTheme.of(context).colors;
    return ExcludeSemantics(
      child: Wrap(
        spacing: NestSpace.sm,
        runSpacing: NestSpace.sm,
        children: [
          for (var index = 0; index < cap; index += 1)
            index < earned
                ? Icon(
                    LucideIcons.gift,
                    size: NestSize.iconLarge,
                    color: colors.accentInk,
                  )
                : Icon(
                    LucideIcons.gift,
                    size: NestSize.iconLarge,
                    color: colors.inkTertiary,
                  ),
        ],
      ),
    );
  }
}
