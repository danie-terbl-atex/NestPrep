import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';

/// Back a week, forward a week, and — once away — the way home to this one.
class WeekPager extends StatelessWidget {
  const WeekPager({
    required this.label,
    required this.isThisWeek,
    required this.onPrevious,
    required this.onNext,
    required this.onThisWeek,
    super.key,
  });

  final String label;
  final bool isThisWeek;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onThisWeek;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final pager = Row(
      children: [
        NestIconButton(
          icon: Icons.chevron_left,
          label: MentalLoadCopy.previousWeek,
          variant: NestIconButtonVariant.plain,
          onPressed: onPrevious,
        ),
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: nest.text.bodyStrong.copyWith(color: nest.colors.ink),
          ),
        ),
        NestIconButton(
          icon: Icons.chevron_right,
          label: MentalLoadCopy.nextWeek,
          variant: NestIconButtonVariant.plain,
          onPressed: onNext,
        ),
      ],
    );
    if (isThisWeek) return pager;
    // The way home sits under the pager rather than beside it: at 200% text
    // there is no room for it on a 360-wide phone (`FE-14`).
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        pager,
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: NestButton(
            label: MentalLoadCopy.thisWeek,
            variant: NestButtonVariant.ghost,
            size: NestButtonSize.small,
            isExpanded: false,
            onPressed: onThisWeek,
          ),
        ),
      ],
    );
  }
}
