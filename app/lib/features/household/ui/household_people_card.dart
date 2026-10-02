import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/household_route.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/household_view.dart';

/// Who is in the household, at the top of More: their faces, how many, and
/// the way to the people screen. It replaces the unnamed people button every
/// tab's header used to carry (design-system ADR-0005).
///
/// It **pushes**: the people screen is a detail of More, so back comes back
/// here (`FE-17`).
class HouseholdPeopleCard extends StatelessWidget {
  const HouseholdPeopleCard({required this.view, super.key});

  final HouseholdView view;

  /// Enough faces to recognise the household; the count says the rest.
  static const _shownFaces = 6;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final members = view.members;
    return Semantics(
      button: true,
      container: true,
      child: NestCard(
        onTap: () =>
            context.push(HouseholdRoute.householdPathFor(view.household.id)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(MoreCopy.peopleTitle, style: nest.text.title),
                      const SizedBox(height: NestSpace.xxs),
                      Text(
                        MoreCopy.peopleCount(members.length),
                        style: nest.text.caption.copyWith(
                          color: nest.colors.inkSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  LucideIcons.chevronRight,
                  size: NestSize.iconMedium,
                  color: nest.colors.inkTertiary,
                ),
              ],
            ),
            if (members.isNotEmpty) ...[
              const SizedBox(height: NestSpace.md),
              Wrap(
                spacing: NestSpace.sm,
                runSpacing: NestSpace.sm,
                children: [
                  for (final member in members.take(_shownFaces))
                    NestAvatar(
                      key: ValueKey(member.id),
                      name: member.displayName,
                      color: member.color,
                      isHighlighted: member.isClaimedBy(view.viewerUid),
                    ),
                ],
              ),
            ],
            const SizedBox(height: NestSpace.md),
            Text(
              view.viewerIsAdmin
                  ? MoreCopy.peopleManage
                  : MoreCopy.peopleManageForMembers,
              style: nest.text.label.copyWith(color: nest.colors.accentInk),
            ),
          ],
        ),
      ),
    );
  }
}
