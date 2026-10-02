import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';

/// The events are on the calendar: how many, and the two ways on.
class LetterAddedPanel extends StatelessWidget {
  const LetterAddedPanel({
    required this.added,
    required this.onSeeTheWeek,
    required this.onSnapAnother,
    super.key,
  });

  final int added;
  final VoidCallback onSeeTheWeek;
  final VoidCallback onSnapAnother;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    // Scrollable, so at 200% text on a small phone nothing is pushed off the
    // edge (`FE-14`).
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: NestSpace.xxl),
        child: NestRiseIn(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(
                child: NestIconTile(
                  icon: LucideIcons.calendarCheck,
                  tint: NestTileTint.basil,
                  size: NestSize.avatarLarge,
                ),
              ),
              const SizedBox(height: NestSpace.lg),
              Text(
                SchoolLetterCopy.addedTitle(added),
                style: nest.text.title.copyWith(color: nest.colors.ink),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: NestSpace.sm),
              Text(
                SchoolLetterCopy.addedBody,
                style: nest.text.bodySecondary,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: NestSpace.xxl),
              NestButton(
                label: SchoolLetterCopy.seeTheWeek,
                icon: LucideIcons.calendarRange,
                onPressed: onSeeTheWeek,
              ),
              const SizedBox(height: NestSpace.sm),
              NestButton(
                label: SchoolLetterCopy.snapAnother,
                variant: NestButtonVariant.ghost,
                onPressed: onSnapAnother,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
