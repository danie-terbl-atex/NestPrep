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
    super.key,
  });

  final JobSafety safety;
  final VoidCallback onReady;

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
        NestRiseIn(index: 1, child: SafetyPanel(safety: safety)),
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
