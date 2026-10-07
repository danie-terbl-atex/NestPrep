import 'package:flutter/widgets.dart';

import '../tokens/nest_member_palette.dart';
import '../tokens/nest_spacing.dart';
import '../tokens/nest_theme.dart';

/// A small filled circle in a member colour — a satellite on the welcome's
/// orbit. Decoration only: it carries no meaning and no semantics, so it is
/// only ever used inside something that is labelled as a whole (`FE-13`).
class NestDot extends StatelessWidget {
  const NestDot({required this.color, this.size = NestSize.dot, super.key});

  final MemberColor color;
  final double size;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: NestTheme.of(context).members.of(color).fill,
      shape: BoxShape.circle,
    ),
    child: SizedBox.square(dimension: size),
  );
}
