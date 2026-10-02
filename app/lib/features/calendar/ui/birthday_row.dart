import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/household_route.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/birthday_occurrence.dart';
import 'member_stripe.dart';

/// A birthday on a day's agenda. It looks like an event row and behaves like
/// nothing else on the calendar: there is no event behind it to edit, delete or
/// skip, because it is derived from the member's profile every time the week is
/// drawn (birthdays ADR-0001).
///
/// So the row says where it comes from and goes there. A capability that can
/// only be finished on another screen has to carry the way to that screen, or
/// it is finished everywhere except the screen —
/// `lessons/a-capability-can-be-finished-everywhere-except-the-screen`.
class BirthdayRow extends StatelessWidget {
  const BirthdayRow({
    required this.occurrence,
    required this.householdId,
    super.key,
  });

  final BirthdayOccurrence occurrence;
  final String householdId;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final member = occurrence.member;
    final age = occurrence.age;
    final title = age == null
        ? AppCopy.birthdayOf(member.displayName)
        : AppCopy.birthdayTurning(member.displayName, age);

    return NestCard(
      variant: NestCardVariant.flat,
      padding: EdgeInsets.zero,
      child: Semantics(
        button: true,
        label: '$title. ${AppCopy.calendarBirthdayOpenProfile}',
        excludeSemantics: true,
        child: InkWell(
          borderRadius: BorderRadius.circular(NestRadius.lg),
          // It **pushes**, like the header's household link and for the same
          // reason: the household opens over the week, so back comes back to
          // the week. Replacing would leave nothing to pop and the system back
          // button would close the app (`FE-17`).
          onTap: () =>
              context.push(HouseholdRoute.householdPathFor(householdId)),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MemberStripe(colors: [member.color]),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(NestSpace.md),
                    child: Row(
                      children: [
                        const NestIconTile(
                          icon: Icons.cake_outlined,
                          tint: NestTileTint.guava,
                          size: NestSize.avatarMedium,
                        ),
                        const SizedBox(width: NestSpace.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: nest.text.bodyStrong.copyWith(
                                  color: nest.colors.ink,
                                ),
                              ),
                              const SizedBox(height: NestSpace.xxs),
                              // Not "All day · who", which is what an event
                              // says. A different sentence, because it is a
                              // different kind of thing and tapping it does
                              // something else.
                              Text(
                                '${AppCopy.calendarAllDay} · '
                                '${AppCopy.calendarBirthdayFromProfile}',
                                style: nest.text.caption.copyWith(
                                  color: nest.colors.inkTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: nest.colors.inkTertiary,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
