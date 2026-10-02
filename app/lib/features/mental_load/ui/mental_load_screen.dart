import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../../../shared/ui/back_leading.dart';
import '../model/week_load.dart';
import '../state/mental_load_controller.dart';
import 'card_capture.dart';
import 'mental_load_body.dart';
import 'week_pager.dart';

/// Who is handling what this week (calendar ADR-0006): the household's
/// adults, what each picked up, and a card each can share as a picture. It
/// is derived from reads the app already makes; the screen stores nothing.
class MentalLoadScreen extends StatelessWidget {
  const MentalLoadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<MentalLoadController>();
    final failure = controller.actionFailure;
    final weekLabel = NestDates.weekRange(controller.weekStart);
    return NestScaffold(
      leading: backLeading(context),
      title: MentalLoadCopy.title,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (failure != null) ...[
            NestBanner(
              message: AppCopy.failure(failure),
              tone: NestBannerTone.danger,
              actionLabel: AppCopy.back,
              onAction: controller.dismissActionFailure,
            ),
            const SizedBox(height: NestSpace.md),
          ],
          WeekPager(
            label: weekLabel,
            isThisWeek: controller.isThisWeek,
            onPrevious: controller.goToPreviousWeek,
            onNext: controller.goToNextWeek,
            onThisWeek: controller.goToThisWeek,
          ),
          const SizedBox(height: NestSpace.md),
          Expanded(
            child: NestAsyncView<WeekLoad>(
              state: controller.week,
              isEmpty: (week) => week.isEmpty && week.adults.length > 1,
              onRetry: controller.retry,
              emptyBuilder: (_) => const NestEmptyView(
                icon: LucideIcons.handHeart,
                title: MentalLoadCopy.emptyTitle,
                message: MentalLoadCopy.emptyBody,
              ),
              dataBuilder: (context, week) => MentalLoadBody(
                week: week,
                weekLabel: weekLabel,
                onShare: (adult, key) async {
                  final png = await captureCard(key);
                  await controller.share(
                    png: png,
                    text: MentalLoadCopy.shareText(
                      adult.member.displayName,
                      weekLabel,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
