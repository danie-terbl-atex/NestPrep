import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/week_load.dart';

/// The week as one bar, a stretch per adult in their own colour, with a
/// legend that says each name and number — colour is never the only signal
/// (`FE-13`). Adults keep the household's order: it is a picture of the week,
/// not a ranking (calendar ADR-0006).
class LoadSplitBar extends StatelessWidget {
  const LoadSplitBar({required this.week, super.key});

  final WeekLoad week;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final shares = [
      for (final adult in week.adults)
        if (adult.total > 0) adult,
    ];
    final label = [
      for (final adult in week.adults)
        MentalLoadCopy.splitPart(adult.member.displayName, adult.total),
    ].join('; ');
    return Semantics(
      container: true,
      label: '${MentalLoadCopy.splitLabel}: $label',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(NestRadius.sm),
            child: SizedBox(
              height: NestSpace.md,
              child: Row(
                // Stretched, or a childless ColoredBox is zero pixels tall.
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final adult in shares)
                    Expanded(
                      flex: adult.total,
                      child: ColoredBox(
                        color: nest.members.of(adult.member.color).fill,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: NestSpace.sm),
          Wrap(
            spacing: NestSpace.md,
            runSpacing: NestSpace.xs,
            children: [
              for (final adult in week.adults)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    NestAvatar(
                      name: adult.member.displayName,
                      color: adult.member.color,
                      size: NestSize.avatarSmall,
                    ),
                    const SizedBox(width: NestSpace.xs),
                    // Flexible, so a long name at 200% text wraps inside
                    // the legend rather than past the phone's edge.
                    Flexible(
                      child: Text(
                        MentalLoadCopy.splitPart(
                          adult.member.displayName,
                          adult.total,
                        ),
                        style: nest.text.caption.copyWith(
                          color: nest.colors.inkSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
