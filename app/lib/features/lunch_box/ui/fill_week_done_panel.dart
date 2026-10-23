import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/lunch_route.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../state/fill_week_controller.dart';

/// Step 3 (lunch-box ADR-0020): the week is in — how many compartments went
/// in, and how many could not and why, then back to the board, where they
/// already show. No Twig: no AI did this (design-system ADR-0012).
class FillWeekDonePanel extends StatelessWidget {
  const FillWeekDonePanel({super.key});

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final controller = context.watch<FillWeekController>();
    final written = controller.written;
    if (written == null) return const SizedBox.shrink();
    final name = controller.childWeek?.child.member.displayName ?? '';
    return ListView(
      padding: const EdgeInsets.only(bottom: NestSpace.huge),
      children: [
        const SizedBox(height: NestSpace.xl),
        const Center(
          child: NestIconTile(
            icon: LucideIcons.check,
            tint: NestTileTint.basil,
            size: NestSize.mark,
            iconSize: NestSize.iconMark,
          ),
        ),
        const SizedBox(height: NestSpace.xl),
        Semantics(
          liveRegion: true,
          child: Text(
            FillWeekCopy.doneHeadline(name),
            textAlign: TextAlign.center,
            style: nest.text.headline,
          ),
        ),
        const SizedBox(height: NestSpace.sm),
        Text(
          written.lunches == 0
              ? FillWeekCopy.packedNothing
              : FillWeekCopy.packed(written.lunches),
          textAlign: TextAlign.center,
          style: nest.text.bodySecondary,
        ),
        if (written.skipped > 0) ...[
          const SizedBox(height: NestSpace.md),
          NestBanner(
            message: FillWeekCopy.skipped(written.skipped),
            tone: NestBannerTone.warning,
          ),
        ],
        const SizedBox(height: NestSpace.xl),
        NestButton(
          key: const ValueKey('fill-week-done'),
          label: FillWeekCopy.doneAction,
          icon: LucideIcons.arrowLeft,
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go(LunchRoute.pathFor(controller.householdId)),
        ),
      ],
    );
  }
}
