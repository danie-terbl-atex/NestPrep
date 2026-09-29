import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/safety/job_safety.dart';
import 'safety_panel.dart';

/// The first thing the helper sees: the safety for this job, in full, before
/// a single step — and one clear way on once she has read it
/// (home-care ADR-0002).
class BeforeYouStart extends StatelessWidget {
  const BeforeYouStart({
    required this.safety,
    required this.onReady,
    this.rowBuilder,
    this.isTranslated = false,
    super.key,
  });

  final JobSafety safety;
  final VoidCallback onReady;

  /// How each line is drawn — in the helper's language on her screens
  /// (home-care ADR-0006).
  final SafetyRowBuilder? rowBuilder;

  /// Whether the lines are shown translated, which says why the English
  /// stays beside them.
  final bool isTranslated;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NestRiseIn(
          child: Row(
            children: [
              NestIconTile(
                icon: safety.hasDangers
                    ? Icons.dangerous_outlined
                    : Icons.health_and_safety_outlined,
                tint: safety.hasDangers
                    ? NestTileTint.peach
                    : NestTileTint.mint,
              ),
              const SizedBox(width: NestSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      HomeCareSafetyCopy.beforeYouStart,
                      style: nest.text.headline,
                    ),
                    Text(
                      HomeCareSafetyCopy.beforeYouStartBody,
                      style: nest.text.bodySecondary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: NestSpace.xl),
        if (isTranslated) ...[
          const NestBanner(message: HomeCareLanguageCopy.safetyStaysInEnglish),
          const SizedBox(height: NestSpace.lg),
        ],
        NestRiseIn(
          index: 1,
          child: SafetyPanel(safety: safety, rowBuilder: rowBuilder),
        ),
        const SizedBox(height: NestSpace.xl),
        NestButton(
          label: HomeCareSafetyCopy.readIt,
          icon: Icons.check,
          onPressed: onReady,
        ),
      ],
    );
  }
}
