import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../../household/model/member.dart';
import '../model/nanny_pickups.dart';
import 'collector_look.dart';

/// The usual week, child by child: who collects on each weekday, when and
/// where. Family sees every weekday, so an unset one is a tap to set; a carer
/// sees only the days there is a run.
class SchoolRunWeek extends StatelessWidget {
  const SchoolRunWeek({
    required this.children,
    required this.pickups,
    required this.memberById,
    required this.onEdit,
    super.key,
  });

  final List<Member> children;
  final NannyPickups pickups;
  final Member? Function(String memberId) memberById;

  /// Null for anybody who is not family.
  final void Function(Member child, int weekday)? onEdit;

  static const _weekdays = [1, 2, 3, 4, 5, 6, 7];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const NestSectionHeader(title: NannyPickupCopy.week),
        for (final child in children)
          ..._child(context, child, [
            for (final weekday in _weekdays) ?_row(context, child, weekday),
          ]),
      ],
    );
  }

  List<Widget> _child(BuildContext context, Member child, List<Widget> rows) {
    final nest = NestTheme.of(context);
    return [
      const SizedBox(height: NestSpace.md),
      Text(
        child.displayName,
        style: nest.text.label.copyWith(color: nest.colors.inkSecondary),
      ),
      const SizedBox(height: NestSpace.sm),
      if (rows.isEmpty)
        Text(NannyPickupCopy.noWeekYet, style: nest.text.bodySecondary)
      else
        NestCard(
          variant: NestCardVariant.flat,
          padding: EdgeInsets.zero,
          child: Column(children: rows),
        ),
    ];
  }

  Widget? _row(BuildContext context, Member child, int weekday) {
    final run = pickups.runFor(child.id, weekday);
    final edit = onEdit;
    if (run == null && edit == null) return null;
    final look = run == null
        ? null
        : lookOfCollector(
            run.collector,
            pickups: pickups,
            memberById: memberById,
          );
    final details = [
      if (run?.atMinute case final minute?) NestDates.timeOfDay(minute),
      ?run?.place,
    ].join(' · ');
    return NestListRow(
      key: ValueKey('${child.id}/$weekday'),
      title: NannyPickupCopy.weekdayName(weekday),
      subtitle: look == null
          ? NannyPickupCopy.notSet
          : [look.name, if (details.isNotEmpty) details].join(' · '),
      trailing: edit == null ? null : const Icon(LucideIcons.chevronRight),
      onTap: edit == null ? null : () => edit(child, weekday),
    );
  }
}
