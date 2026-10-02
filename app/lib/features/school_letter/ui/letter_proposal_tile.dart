import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/time/calendar_date.dart';
import '../../calendar/ui/event_summary_chips.dart';
import '../../household/model/member.dart';
import '../model/review_item.dart';

/// One proposed event on the review list: the tick, what it is, the chips the
/// week will show it with, what to bring — and a way to change it. The whole
/// row toggles the tick, like a grocery line; changing it is its own button,
/// so the two gestures cannot be confused.
class LetterProposalTile extends StatelessWidget {
  const LetterProposalTile({
    required this.item,
    required this.today,
    required this.members,
    required this.onToggle,
    required this.onEdit,
    super.key,
  });

  final ReviewItem item;
  final CalendarDate today;

  /// The members it is for, already looked up.
  final List<Member> members;
  final VoidCallback? onToggle;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final proposal = item.proposal;
    final note = proposal.note;
    return NestCard(
      variant: item.isTicked ? NestCardVariant.raised : NestCardVariant.flat,
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(NestRadius.lg),
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.all(NestSpace.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                checked: item.isTicked,
                label: item.isTicked
                    ? SchoolLetterCopy.ticked(proposal.title)
                    : SchoolLetterCopy.unticked(proposal.title),
                excludeSemantics: true,
                child: Icon(
                  item.isTicked ? LucideIcons.circleCheck : LucideIcons.circle,
                  color: item.isTicked
                      ? nest.colors.success
                      : nest.colors.outlineStrong,
                  size: NestSize.iconLarge,
                ),
              ),
              const SizedBox(width: NestSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      proposal.title,
                      style: nest.text.bodyStrong.copyWith(
                        color: item.isTicked
                            ? nest.colors.ink
                            : nest.colors.inkTertiary,
                      ),
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
                    if (note != null) ...[
                      const SizedBox(height: NestSpace.sm),
                      Text(
                        note,
                        style: nest.text.caption.copyWith(
                          color: nest.colors.inkSecondary,
                        ),
                      ),
                    ],
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: NestButton(
                        label: SchoolLetterCopy.edit,
                        icon: LucideIcons.pencil,
                        variant: NestButtonVariant.ghost,
                        size: NestButtonSize.small,
                        isExpanded: false,
                        onPressed: onEdit,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
