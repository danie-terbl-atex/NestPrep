import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../model/co_parent_home.dart';

/// A home's colour beside its name — the legend every two-homes screen and
/// band reads by. The colour is never the only signal: the name is always
/// there too (`FE-13`).
class HomeSwatch extends StatelessWidget {
  const HomeSwatch({required this.home, this.caption, super.key});

  final CoParentHome home;

  /// A word after the name — *this home*.
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final text = caption == null ? home.name : '${home.name} · $caption';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        HomeDot(home: home),
        const SizedBox(width: NestSpace.sm),
        Flexible(
          child: Text(
            text,
            style: nest.text.label.copyWith(color: nest.colors.inkSecondary),
          ),
        ),
      ],
    );
  }
}

/// The dot alone, for where the name is already said beside it.
class HomeDot extends StatelessWidget {
  const HomeDot({required this.home, super.key});

  final CoParentHome home;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return ExcludeSemantics(
      child: Container(
        width: NestSpace.md,
        height: NestSpace.md,
        decoration: BoxDecoration(
          color: nest.members.of(home.color).fill,
          shape: BoxShape.circle,
          border: Border.all(color: nest.colors.outline),
        ),
      ),
    );
  }
}
