import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/quick_add_copy.dart';
import '../../../shared/time/calendar_date.dart';
import '../../household/model/member.dart';
import '../model/quick_add/quick_add_result.dart';
import 'event_summary_chips.dart';

/// What quick add understood, laid out the way the week will show it — the
/// title, then a chip for each thing it read: the day, the time, the repeat,
/// who it is for (calendar ADR-0004). Nothing is saved until [onAdd]; [onEdit]
/// opens the full sheet with all of it filled in.
class QuickAddPreview extends StatelessWidget {
  const QuickAddPreview({
    required this.proposal,
    required this.today,
    required this.members,
    required this.onAdd,
    required this.onEdit,
    super.key,
  });

  final QuickAddProposal proposal;
  final CalendarDate today;

  /// The members it is for, already looked up.
  final List<Member> members;
  final VoidCallback onAdd;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Semantics(
      container: true,
      label: QuickAddCopy.previewLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            proposal.title,
            style: nest.text.bodyStrong.copyWith(color: nest.colors.ink),
          ),
          const SizedBox(height: NestSpace.sm),
          EventSummaryChips(
            date: proposal.date,
            today: today,
            startMinute: proposal.startMinute,
            endMinute: proposal.endMinute,
            recurrence: proposal.recurrence,
            members: members,
          ),
          const SizedBox(height: NestSpace.md),
          // A wrap, so at 200% text the two stack rather than push past the
          // edge (`FE-14`).
          Wrap(
            alignment: WrapAlignment.end,
            spacing: NestSpace.sm,
            runSpacing: NestSpace.sm,
            children: [
              NestButton(
                label: QuickAddCopy.edit,
                variant: NestButtonVariant.ghost,
                size: NestButtonSize.small,
                isExpanded: false,
                onPressed: onEdit,
              ),
              NestButton(
                label: QuickAddCopy.add,
                icon: Icons.add,
                size: NestButtonSize.small,
                isExpanded: false,
                onPressed: onAdd,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
