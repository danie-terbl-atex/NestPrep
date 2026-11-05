import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';

/// The photo is with the model: what is happening, over the shape of the
/// list that is coming, so the screen holds its layout (`FE-08`). Twig,
/// thinking, is the AI at work (design-system ADR-0012).
class ListReadingPanel extends StatelessWidget {
  const ListReadingPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Semantics(
      liveRegion: true,
      label: ListScanCopy.readingTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const NestTwig(pose: NestTwigPose.thinking),
              const SizedBox(width: NestSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ListScanCopy.readingTitle,
                      style: nest.text.title.copyWith(color: nest.colors.ink),
                    ),
                    Text(
                      ListScanCopy.readingBody,
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
          const Expanded(child: NestLoadingView(rows: 5)),
        ],
      ),
    );
  }
}
