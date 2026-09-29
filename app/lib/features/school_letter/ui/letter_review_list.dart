import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/failure/app_failure.dart';
import '../../../shared/time/calendar_date.dart';
import '../../household/model/member.dart';
import '../model/review_item.dart';
import 'letter_confirm_bar.dart';
import 'letter_proposal_tile.dart';

/// What the letter proposed, to tick, change and confirm (calendar ADR-0005).
/// Nothing on it is on the calendar yet; the button at the foot is the only
/// thing that adds anything, and it says how many.
///
/// A letter with no dates is this view too, saying so in place with the way
/// to another letter beside it (`FE-08`).
class LetterReviewList extends StatelessWidget {
  const LetterReviewList({
    required this.items,
    required this.today,
    required this.members,
    required this.isSaving,
    required this.onToggle,
    required this.onEdit,
    required this.onConfirm,
    required this.onStartOver,
    this.callsLeft,
    this.failure,
    this.onDismissFailure,
    super.key,
  });

  final List<ReviewItem> items;
  final CalendarDate today;
  final List<Member> members;
  final bool isSaving;
  final ValueChanged<int> onToggle;
  final ValueChanged<ReviewItem> onEdit;
  final VoidCallback onConfirm;
  final VoidCallback onStartOver;
  final int? callsLeft;
  final AppFailure? failure;
  final VoidCallback? onDismissFailure;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final ticked = items.where((item) => item.isTicked).length;
    final left = callsLeft;
    final shown = failure;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: NestSpace.xl),
            children: [
              if (shown != null) ...[
                NestBanner(
                  message: AppCopy.failure(shown),
                  tone: NestBannerTone.warning,
                  actionLabel: AppCopy.back,
                  onAction: onDismissFailure,
                ),
                const SizedBox(height: NestSpace.lg),
              ],
              Text(
                items.isEmpty
                    ? SchoolLetterCopy.noneTitle
                    : SchoolLetterCopy.found(items.length),
                style: nest.text.title.copyWith(color: nest.colors.ink),
              ),
              const SizedBox(height: NestSpace.xs),
              Text(
                items.isEmpty
                    ? SchoolLetterCopy.noneBody
                    : SchoolLetterCopy.reviewBody,
                style: nest.text.body.copyWith(color: nest.colors.inkSecondary),
              ),
              if (left != null) ...[
                const SizedBox(height: NestSpace.xs),
                Text(
                  AiCopy.callsLeft(left),
                  style: nest.text.caption.copyWith(
                    color: nest.colors.inkTertiary,
                  ),
                ),
              ],
              const SizedBox(height: NestSpace.lg),
              for (final (index, item) in items.indexed)
                Padding(
                  key: ValueKey(item.key),
                  padding: const EdgeInsets.only(bottom: NestSpace.sm),
                  child: NestRiseIn(
                    index: index,
                    child: LetterProposalTile(
                      item: item,
                      today: today,
                      members: [
                        for (final member in members)
                          if (item.proposal.memberIds.contains(member.id))
                            member,
                      ],
                      // Nothing changes under a save in flight.
                      onToggle: isSaving ? null : () => onToggle(item.key),
                      onEdit: isSaving ? null : () => onEdit(item),
                    ),
                  ),
                ),
            ],
          ),
        ),
        LetterConfirmBar(
          ticked: ticked,
          hasItems: items.isNotEmpty,
          isSaving: isSaving,
          onConfirm: onConfirm,
          onStartOver: onStartOver,
        ),
      ],
    );
  }
}
