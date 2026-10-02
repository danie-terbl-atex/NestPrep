import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/family_route.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../../family_profiles/model/family_access.dart';
import '../../household/model/household_view.dart';
import '../../lunch_box/model/lunch_board.dart';
import '../../lunch_box/state/lunch_board_controller.dart';
import '../../lunch_box/ui/art/lunch_photo.dart';
import 'today_async.dart';
import 'today_section.dart';

/// The next box that matters for each child, as a photo card that opens
/// the lunch tab.
class TodayLunchSection extends StatelessWidget {
  const TodayLunchSection({required this.onOpen, super.key});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LunchBoardController>();
    return TodaySection(
      eyebrow: TodayCopy.lunchEyebrow,
      child: TodayAsync<LunchBoard>(
        state: controller.board,
        builder: (context, board) => Column(
          children: [
            if (board.children.isEmpty) const _FirstChild(),
            for (final childWeek in board.children)
              Padding(
                padding: const EdgeInsets.only(bottom: NestSpace.lg),
                child: _ChildLunch(
                  board: board,
                  childWeek: childWeek,
                  isOneOfSeveral: board.children.length > 1,
                  onOpen: onOpen,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A household with nobody to pack for yet: the way to the one place a
/// child is added, for whoever may add one.
class _FirstChild extends StatelessWidget {
  const _FirstChild();

  @override
  Widget build(BuildContext context) {
    final view = context.read<HouseholdView>();
    if (!FamilyAccess.of(view).seesEveryProfile) return const SizedBox.shrink();
    return NestCard(
      variant: NestCardVariant.tinted,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const NestIntro(
            title: TodayCopy.firstChildTitle,
            body: TodayCopy.firstChildBody,
            isLarge: false,
          ),
          const SizedBox(height: NestSpace.lg),
          NestButton(
            label: TodayCopy.addChild,
            icon: LucideIcons.userPlus,
            onPressed: () =>
                context.push(FamilyRoute.pathFor(view.household.id)),
          ),
        ],
      ),
    );
  }
}

class _ChildLunch extends StatelessWidget {
  const _ChildLunch({
    required this.board,
    required this.childWeek,
    required this.isOneOfSeveral,
    required this.onOpen,
  });

  final LunchBoard board;
  final LunchChildWeek childWeek;
  final bool isOneOfSeveral;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final day = board.focusDayOf(childWeek);
    final name = childWeek.child.member.displayName;
    final picks = [for (final (_, pick) in day.box.filled) pick.name];
    final title = picks.isEmpty ? TodayCopy.nothingPacked : picks.first;
    final eyebrow =
        '${NestDates.relative(day.date, board.today)} · '
        '${TodayCopy.lunchFor(name)}';
    if (picks.isEmpty) {
      return NestCard(
        onTap: onOpen,
        child: Row(
          children: [
            NestAvatar(name: name, color: childWeek.child.member.color),
            const SizedBox(width: NestSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  NestEyebrow(eyebrow),
                  Text(title, style: nest.text.title),
                ],
              ),
            ),
            const SizedBox(width: NestSpace.sm),
            Flexible(
              child: NestButton(
                label: TodayCopy.planLunch,
                onPressed: onOpen,
                variant: NestButtonVariant.tonal,
                size: NestButtonSize.small,
                isExpanded: false,
              ),
            ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NestPhotoCard(
          heroTag: 'today-lunch-${childWeek.childId}',
          photo: LunchPhoto(
            box: day.box,
            childId: childWeek.childId,
            date: day.date,
          ),
          actionLabel: TodayCopy.viewLunch,
          aspectRatio: isOneOfSeveral ? 16 / 9 : 4 / 3,
          actionIcon: LucideIcons.arrowUpRight,
          semanticsLabel: '$name. ${picks.join(', ')}',
          onTap: onOpen,
        ),
        const SizedBox(height: NestSpace.md),
        NestEyebrow(eyebrow),
        const SizedBox(height: NestSpace.xs),
        Text(title, style: nest.text.screenTitle),
        if (picks.length > 1)
          Text(picks.skip(1).join(', '), style: nest.text.bodySecondary),
      ],
    );
  }
}
