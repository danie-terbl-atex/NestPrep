import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/time/household_clock.dart';
import '../../household/model/member.dart';
import '../model/shift.dart';
import 'hub_clock.dart';

/// Who is on shift, since when, and the children they are looking after —
/// the calm line at the top of shift mode.
class ShiftHeader extends StatelessWidget {
  const ShiftHeader({
    required this.shift,
    required this.carer,
    required this.children,
    super.key,
  });

  final Shift shift;
  final Member? carer;
  final List<Member> children;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final clock = context.read<HouseholdClock>();
    final started = shift.startedAt;
    final person = carer;
    return Row(
      children: [
        if (person != null) ...[
          NestAvatar(
            name: person.displayName,
            color: person.color,
            size: NestSize.avatarLarge,
          ),
          const SizedBox(width: NestSpace.md),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(person?.displayName ?? '', style: nest.text.headline),
              Text(
                NannyShiftCopy.shiftStarted(
                  started == null
                      ? NannyShiftCopy.summaryPending
                      : clock.timeOf(started),
                ),
                style: nest.text.bodySecondary,
              ),
              if (children.isNotEmpty) ...[
                const SizedBox(height: NestSpace.sm),
                Wrap(
                  spacing: NestSpace.xs,
                  runSpacing: NestSpace.xs,
                  children: [
                    for (final child in children)
                      NestTag(label: child.displayName, icon: LucideIcons.baby),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
