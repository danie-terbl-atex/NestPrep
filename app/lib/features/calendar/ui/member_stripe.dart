import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';

/// The colours of everybody a row is for, stacked down its left edge. Shared by
/// the event row and the birthday row, so a day reads as one column of colour
/// rather than two that nearly match (`ENG-01`).
///
/// Colour is never the only thing saying who a row is for — the names are in
/// the subtitle (`FE-13`).
class MemberStripe extends StatelessWidget {
  const MemberStripe({required this.colors, super.key});

  final List<MemberColor> colors;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final stripes = colors.isEmpty
        ? [nest.colors.outlineStrong]
        : [for (final color in colors) nest.members.of(color).fill];
    return SizedBox(
      width: NestSpace.xs,
      child: Column(
        children: [
          for (final color in stripes)
            Expanded(child: ColoredBox(color: color)),
        ],
      ),
    );
  }
}
