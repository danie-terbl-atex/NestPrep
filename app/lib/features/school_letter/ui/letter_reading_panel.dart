import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';

/// The letter is with the model: what is happening, in words, over the shape
/// of the list that is coming — so the screen holds its layout rather than
/// collapsing to a spinner (`FE-08`).
class LetterReadingPanel extends StatelessWidget {
  const LetterReadingPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Semantics(
      liveRegion: true,
      label: SchoolLetterCopy.readingTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const NestIconTile(
                icon: Icons.auto_awesome_outlined,
                tint: NestTileTint.sky,
              ),
              const SizedBox(width: NestSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      SchoolLetterCopy.readingTitle,
                      style: nest.text.title.copyWith(color: nest.colors.ink),
                    ),
                    Text(
                      SchoolLetterCopy.readingBody,
                      style: nest.text.body.copyWith(
                        color: nest.colors.inkSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: NestSpace.xl),
          const Expanded(child: NestLoadingView(rows: 3)),
        ],
      ),
    );
  }
}
