import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/time/calendar_date.dart';
import '../model/weekly_numbers.dart';
import '../state/beta_numbers_controller.dart';
import 'weekly_numbers_card.dart';

/// The three beta numbers, week by week, for whoever holds the reader claim —
/// Daniel, during the beta (product-analytics ADR-0001).
///
/// Reached from the account sheet, and only offered to a reader; anybody else
/// who finds the path is refused by the rules and sees the error state, not
/// the numbers. It is outside the household shell on purpose: the numbers are
/// about every family, never a view of this one.
class BetaNumbersScreen extends StatelessWidget {
  const BetaNumbersScreen({super.key});

  static const path = '/beta-numbers';

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BetaNumbersController>();
    const copy = AppCopy.productAnalytics;
    return NestScaffold(
      title: copy.title,
      subtitle: copy.subtitle,
      leading: context.canPop()
          ? NestIconButton(
              icon: LucideIcons.arrowLeft,
              label: AppCopy.back,
              variant: NestIconButtonVariant.plain,
              onPressed: context.pop,
            )
          : null,
      body: NestAsyncView<List<WeeklyNumbers>>(
        state: controller.weeks,
        isEmpty: (weeks) => weeks.isEmpty,
        onRetry: controller.retry,
        emptyBuilder: (_) => NestEmptyView(
          title: copy.emptyTitle,
          message: copy.emptyBody,
          icon: LucideIcons.chartLine,
        ),
        dataBuilder: (_, weeks) =>
            _TheWeeks(weeks: weeks, today: controller.today),
      ),
    );
  }
}

class _TheWeeks extends StatelessWidget {
  const _TheWeeks({required this.weeks, required this.today});

  final List<WeeklyNumbers> weeks;
  final CalendarDate today;

  static const _staggeredCards = 3;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    const copy = AppCopy.productAnalytics;
    final firstEarlier = weeks.indexWhere(
      (numbers) => numbers.weekStart != today.weekStart,
    );
    return ListView(
      padding: const EdgeInsets.only(bottom: NestSpace.huge),
      children: [
        for (final (index, numbers) in weeks.indexed) ...[
          if (index == firstEarlier) ...[
            NestSectionHeader(title: copy.earlierWeeks),
            const SizedBox(height: NestSpace.sm),
          ],
          NestRiseIn(
            // The stagger stops after the first screenful, so a long list
            // does not keep a card waiting (design-system ADR-0002).
            index: index.clamp(0, _staggeredCards),
            child: WeeklyNumbersCard(
              key: ValueKey(numbers.week),
              numbers: numbers,
              today: today,
              isCurrent: numbers.weekStart == today.weekStart,
            ),
          ),
          const SizedBox(height: NestSpace.lg),
        ],
        NestCard(
          variant: NestCardVariant.tinted,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(copy.howCountedTitle, style: nest.text.title),
              const SizedBox(height: NestSpace.sm),
              Text(copy.howCountedBody, style: nest.text.bodySecondary),
            ],
          ),
        ),
      ],
    );
  }
}
