import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/family_route.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/copy/subscription_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../../avatars/ui/member_avatar.dart';
import '../../family_profiles/model/family_access.dart';
import '../../household/model/household_view.dart';
import '../../lunch_box/model/lunch_board.dart';
import '../../lunch_box/state/lunch_board_controller.dart';
import '../../lunch_box/ui/art/lunch_photo.dart';
import '../../subscriptions/model/premium_feature.dart';
import '../../subscriptions/state/household_entitlement.dart';
import '../../subscriptions/ui/paywall_page.dart';
import 'today_async.dart';
import 'today_section.dart';

/// The next box that matters for each child, a row each, opening the lunch
/// tab — or, for a household without Premium, lunch boxes shown locked
/// (subscriptions ADR-0009), which starts no lunch listener.
class TodayLunchSection extends StatelessWidget {
  const TodayLunchSection({required this.onOpen, super.key});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final entitlement = context.watch<HouseholdEntitlement>();
    if (entitlement.isPremium) return _NextLunches(onOpen: onOpen);
    if (entitlement.entitlement is AsyncLoading) return const SizedBox.shrink();
    return const TodaySection(
      eyebrow: TodayCopy.lunchEyebrow,
      child: _LockedLunches(),
    );
  }
}

class _NextLunches extends StatelessWidget {
  const _NextLunches({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LunchBoardController>();
    return TodaySection(
      eyebrow: TodayCopy.lunchEyebrow,
      actionLabel: TodayCopy.seeAll,
      onAction: onOpen,
      child: TodayAsync<LunchBoard>(
        state: controller.board,
        builder: (context, board) => Column(
          children: [
            if (board.children.isEmpty) const _FirstChild(),
            for (final childWeek in board.children)
              Padding(
                padding: const EdgeInsets.only(bottom: NestSpace.sm),
                child: _ChildLunch(
                  board: board,
                  childWeek: childWeek,
                  onOpen: onOpen,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LockedLunches extends StatelessWidget {
  const _LockedLunches();

  static const _feature = PremiumFeature.lunchBox;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final headline = SubscriptionCopy.headline(_feature);
    return Semantics(
      button: true,
      label: '$headline. ${SubscriptionCopy.lockedHint}',
      excludeSemantics: true,
      child: NestCard(
        variant: NestCardVariant.tinted,
        onTap: () => showPaywall(context, feature: _feature),
        padding: const EdgeInsets.all(NestSpace.md),
        child: Row(
          children: [
            const NestIconTile(icon: LucideIcons.sandwich),
            const SizedBox(width: NestSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(headline, style: nest.text.bodyStrong),
                  const SizedBox(height: NestSpace.xxs),
                  Text(
                    SubscriptionCopy.lockedHint,
                    style: nest.text.bodySecondary,
                  ),
                ],
              ),
            ),
            const SizedBox(width: NestSpace.sm),
            Icon(
              LucideIcons.lock,
              size: NestSize.iconMedium,
              color: nest.colors.inkSecondary,
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

/// One child's next box as a row: a thumbnail of it, whose and when, and
/// what is in it. Compact on purpose — Today leads with the calendar
/// (design-system ADR-0017), and the lunch tab has the full picture.
class _ChildLunch extends StatelessWidget {
  const _ChildLunch({
    required this.board,
    required this.childWeek,
    required this.onOpen,
  });

  final LunchBoard board;
  final LunchChildWeek childWeek;
  final VoidCallback onOpen;

  static const _thumbWidth = 72.0;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final day = board.focusDayOf(childWeek);
    final member = childWeek.child.member;
    final picks = [for (final (_, pick) in day.box.filled) pick.name];
    final eyebrow =
        '${NestDates.relative(day.date, board.today)} · '
        '${TodayCopy.lunchFor(member.displayName)}';
    return Semantics(
      button: true,
      label:
          '$eyebrow. '
          '${picks.isEmpty ? TodayCopy.nothingPacked : picks.join(', ')}',
      excludeSemantics: true,
      child: NestCard(
        onTap: onOpen,
        padding: const EdgeInsets.all(NestSpace.md),
        child: Row(
          children: [
            if (picks.isEmpty)
              MemberAvatar(member: member)
            else
              ClipRRect(
                borderRadius: BorderRadius.circular(NestRadius.sm),
                child: SizedBox(
                  width: _thumbWidth,
                  height: _thumbWidth * 3 / 4,
                  child: LunchPhoto(
                    box: day.box,
                    childId: childWeek.childId,
                    date: day.date,
                  ),
                ),
              ),
            const SizedBox(width: NestSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  NestEyebrow(eyebrow),
                  const SizedBox(height: NestSpace.xxs),
                  Text(
                    picks.isEmpty ? TodayCopy.nothingPacked : picks.join(', '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: nest.text.bodyStrong,
                  ),
                ],
              ),
            ),
            const SizedBox(width: NestSpace.sm),
            Icon(
              picks.isEmpty ? LucideIcons.plus : LucideIcons.chevronRight,
              size: NestSize.iconMedium,
              color: nest.colors.inkSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
