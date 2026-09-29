import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../../../shared/time/calendar_date.dart';
import '../data/two_homes_directory.dart';
import '../model/change_request.dart';
import '../model/co_parent_link.dart';

/// One request between the two homes (household ADR-0004): what was asked,
/// by which home, with its note — and, while it waits, the answers this home
/// may give. Worded as asking and answering, never as winning or losing.
class RequestRow extends StatelessWidget {
  const RequestRow({
    required this.request,
    required this.link,
    required this.childName,
    required this.today,
    required this.canAct,
    required this.isBusy,
    required this.onAnswer,
    super.key,
  });

  final ChangeRequest request;
  final CoParentLink link;
  final String childName;
  final CalendarDate today;

  /// Family in this home, on an active link.
  final bool canAct;
  final bool isBusy;
  final ValueChanged<ChangeAnswer> onAnswer;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final ours = request.proposedBySide == link.ownSide;
    final from = request.from;
    final to = request.to;
    final toSide = request.toSide;
    final schedule = request.schedule;
    final what = switch (request.kind) {
      ChangeKind.swap when from != null && to != null && toSide != null =>
        TwoHomesCopy.swapSummary(
          childName,
          link.homeOf(toSide).name,
          TwoHomesCopy.dateSpan(
            NestDates.full(from, today),
            NestDates.full(to, today),
          ),
        ),
      ChangeKind.schedule when schedule != null => TwoHomesCopy.scheduleSummary(
        schedule.pattern,
      ),
      _ => TwoHomesCopy.status(request.status),
    };
    final note = request.note;
    final answerNote = request.answerNote;
    final answeredBy = request.answeredBySide;

    return NestCard(
      variant: request.isPending
          ? NestCardVariant.raised
          : NestCardVariant.flat,
      padding: const EdgeInsets.all(NestSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  what,
                  style: nest.text.bodyStrong.copyWith(color: nest.colors.ink),
                ),
              ),
              const SizedBox(width: NestSpace.sm),
              NestTag(label: TwoHomesCopy.status(request.status)),
            ],
          ),
          const SizedBox(height: NestSpace.xs),
          Text(
            TwoHomesCopy.askedBy(link.homeOf(request.proposedBySide).name),
            style: nest.text.caption.copyWith(color: nest.colors.inkTertiary),
          ),
          if (note != null) ...[
            const SizedBox(height: NestSpace.sm),
            Text(
              '“$note”',
              style: nest.text.body.copyWith(color: nest.colors.inkSecondary),
            ),
          ],
          if (answerNote != null && answeredBy != null) ...[
            const SizedBox(height: NestSpace.sm),
            Text(
              TwoHomesCopy.answeredNote(
                link.homeOf(answeredBy).name,
                answerNote,
              ),
              style: nest.text.body.copyWith(color: nest.colors.inkSecondary),
            ),
          ],
          if (request.isPending && canAct) ...[
            const SizedBox(height: NestSpace.md),
            if (ours)
              NestButton(
                label: TwoHomesCopy.withdraw,
                variant: NestButtonVariant.outline,
                size: NestButtonSize.small,
                onPressed: isBusy
                    ? null
                    : () => onAnswer(ChangeAnswer.withdraw),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: NestButton(
                      label: TwoHomesCopy.accept,
                      size: NestButtonSize.small,
                      isLoading: isBusy,
                      onPressed: isBusy
                          ? null
                          : () => onAnswer(ChangeAnswer.accept),
                    ),
                  ),
                  const SizedBox(width: NestSpace.sm),
                  Expanded(
                    child: NestButton(
                      label: TwoHomesCopy.decline,
                      variant: NestButtonVariant.outline,
                      size: NestButtonSize.small,
                      onPressed: isBusy
                          ? null
                          : () => onAnswer(ChangeAnswer.decline),
                    ),
                  ),
                ],
              ),
          ],
        ],
      ),
    );
  }
}
