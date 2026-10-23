import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/fill_week_preview.dart';
import '../state/fill_week_controller.dart';
import 'fill_week_day_card.dart';

/// Step 2 (lunch-box ADR-0020): the whole week as the fill would leave it,
/// day by day, each new lunch saying whether a box or NestPrep put it
/// there — then *Fill the week*, which writes, or *Back*. With nothing to
/// add the step says so in place and the way back stays (`FE-08`).
class FillWeekReviewPanel extends StatelessWidget {
  const FillWeekReviewPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final controller = context.watch<FillWeekController>();
    final preview = controller.preview;
    final failure = controller.failure;
    final name = controller.childWeek?.child.member.displayName ?? '';
    final isEmpty = preview == null || preview.isEmpty;
    return ListView(
      padding: const EdgeInsets.only(bottom: NestSpace.huge),
      children: [
        Text(FillWeekCopy.reviewHeadline(name), style: nest.text.headline),
        const SizedBox(height: NestSpace.xs),
        Text(FillWeekCopy.reviewBody, style: nest.text.bodySecondary),
        const SizedBox(height: NestSpace.lg),
        if (isEmpty)
          NestEmptyView(
            icon: LucideIcons.calendarCheck,
            title: preview?.hasNoDaysLeft ?? false
                ? FillWeekCopy.noDaysLeftTitle
                : FillWeekCopy.nothingToFillTitle,
            message: preview?.hasNoDaysLeft ?? false
                ? FillWeekCopy.noDaysLeftBody
                : FillWeekCopy.nothingToFillBody,
          ),
        for (final day in preview?.days ?? const <FillWeekDay>[]) ...[
          FillWeekDayCard(
            key: ValueKey('fill-week-day-${day.date.iso}'),
            day: day,
          ),
          const SizedBox(height: NestSpace.md),
        ],
        if (failure != null) ...[
          const SizedBox(height: NestSpace.sm),
          NestBanner(
            message: AppCopy.failure(failure),
            tone: NestBannerTone.danger,
            actionLabel: AppCopy.back,
            onAction: controller.dismissFailure,
          ),
        ],
        const SizedBox(height: NestSpace.xl),
        NestStepActions(
          nextKey: const ValueKey('fill-week-fill'),
          nextLabel: FillWeekCopy.fillAction,
          nextIcon: LucideIcons.check,
          isBusy: controller.isSaving,
          onNext: isEmpty ? null : controller.fill,
          backLabel: FillWeekCopy.back,
          onBack: controller.isSaving ? null : controller.back,
        ),
      ],
    );
  }
}
