import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../../../shared/time/calendar_date.dart';
import '../model/avatar_creation.dart';
import '../state/creation_step.dart';

class CreationRefusedView extends StatelessWidget {
  const CreationRefusedView({
    required this.refused,
    required this.today,
    required this.onAgain,
    this.onPremium,
    super.key,
  });

  final CreationRefused refused;
  final VoidCallback onAgain;
  final VoidCallback? onPremium;
  final CalendarDate today;

  static const _triesAgain = {
    CreationRefusal.notAllowed,
    CreationRefusal.declined,
    CreationRefusal.unavailable,
  };

  static String nextMonthFrom(CalendarDate today) => NestDates.dayOfYear(
    month: today.month % DateTime.monthsPerYear + 1,
    day: 1,
  );

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final onPremium = this.onPremium;
    final needsPremium = refused.reason == CreationRefusal.premiumRequired;
    return NestCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              NestIconTile(
                icon: needsPremium ? LucideIcons.sparkles : LucideIcons.egg,
                tint: NestTileTint.butter,
              ),
              const SizedBox(width: NestSpace.md),
              Expanded(
                child: Text(
                  AvatarCreationCopy.refusedTitle,
                  style: nest.text.title,
                ),
              ),
            ],
          ),
          const SizedBox(height: NestSpace.md),
          Semantics(
            liveRegion: true,
            child: Text(
              AvatarCreationCopy.refused(
                refused.reason,
                refused.recipe,
                nextMonth: nextMonthFrom(today),
                canBuy: onPremium != null,
              ),
              style: nest.text.body,
            ),
          ),
          const SizedBox(height: NestSpace.xl),
          if (needsPremium && onPremium != null) ...[
            NestButton(
              label: AvatarCreationCopy.seePremium,
              icon: LucideIcons.sparkles,
              onPressed: onPremium,
            ),
            const SizedBox(height: NestSpace.sm),
          ],
          NestButton(
            label: _triesAgain.contains(refused.reason)
                ? AppCopy.retry
                : AppCopy.back,
            variant: needsPremium && onPremium != null
                ? NestButtonVariant.outline
                : NestButtonVariant.primary,
            onPressed: onAgain,
          ),
        ],
      ),
    );
  }
}
