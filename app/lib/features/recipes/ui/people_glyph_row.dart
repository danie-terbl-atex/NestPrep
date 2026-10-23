import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';

/// A small person for everybody being cooked for, filled in Guava with Ink
/// on it, beside the empty places the recipe as written would also feed — so
/// cooking a six-serving pot for four reads as four of six at a glance. The
/// row stops at [cap] and says how many more; the number above it is always
/// the real one. Decoration: the scaler says it in words (`FE-13`).
class PeopleGlyphRow extends StatelessWidget {
  const PeopleGlyphRow({
    required this.people,
    required this.servings,
    super.key,
  });

  final int people;
  final int servings;

  /// Two rows on a phone at most.
  static const cap = 12;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final c = nest.colors;
    final shown = (people > servings ? people : servings).clamp(1, cap);
    final more = people - cap;
    return ExcludeSemantics(
      child: Wrap(
        spacing: NestSpace.xs,
        runSpacing: NestSpace.xs,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (var place = 0; place < shown; place++)
            _Person(isFilled: place < people),
          if (more > 0)
            Padding(
              padding: const EdgeInsets.only(left: NestSpace.xs),
              child: Text(
                '+$more',
                style: nest.text.label.copyWith(color: c.inkSecondary),
              ),
            ),
        ],
      ),
    );
  }
}

class _Person extends StatelessWidget {
  const _Person({required this.isFilled});

  final bool isFilled;

  @override
  Widget build(BuildContext context) {
    final c = NestTheme.of(context).colors;
    return AnimatedContainer(
      duration: NestMotion.of(context).quick,
      curve: NestMotion.standardCurve,
      width: NestSize.avatarSmall,
      height: NestSize.avatarSmall,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isFilled ? c.secondary : c.surface,
        border: Border.all(color: isFilled ? c.secondary : c.outlineStrong),
      ),
      child: Icon(
        LucideIcons.user,
        size: NestSize.iconBadge,
        color: isFilled ? c.onSecondary : c.inkTertiary,
      ),
    );
  }
}
