import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../../household/model/member.dart';
import '../model/pickup_collector.dart';
import '../model/pickup_plan.dart';
import 'collector_avatar.dart';
import 'collector_look.dart';

/// One child's collection today: who comes, when and where, with a change
/// for today named in words and not only in colour (`FE-13`) — and the big
/// way into the door check, because that is what a carer needs when the bell
/// goes.
class TodayPickupCard extends StatelessWidget {
  const TodayPickupCard({
    required this.child,
    required this.plan,
    required this.look,
    required this.onCheck,
    super.key,
  });

  final Member child;

  /// Null when there is no school run today.
  final PickupPlan? plan;

  /// Who [plan] names, as the screen reads them.
  final CollectorLook? look;
  final VoidCallback onCheck;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final today = plan;
    final who = look;
    final isNobody = today == null || today.collector is NobodyCollects;
    final when = [
      if (today?.atMinute case final minute?)
        NannyPickupCopy.at(NestDates.timeOfDay(minute)),
      ?today?.place,
      ?today?.note,
    ].join(' · ');
    return NestCard(
      variant: NestCardVariant.flat,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(child.displayName, style: nest.text.title),
          const SizedBox(height: NestSpace.md),
          if (isNobody || who == null)
            Text(
              today == null
                  ? NannyPickupCopy.noRunToday
                  : NannyPickupCopy.nobodyToday,
              style: nest.text.bodySecondary,
            )
          else
            Row(
              children: [
                CollectorAvatar(look: who),
                const SizedBox(width: NestSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(who.name, style: nest.text.bodyStrong),
                      if (who.detail case final detail?)
                        Text(detail, style: nest.text.bodySecondary),
                      if (when.isNotEmpty) Text(when, style: nest.text.caption),
                    ],
                  ),
                ),
              ],
            ),
          if (today != null && today.isChange) ...[
            const SizedBox(height: NestSpace.sm),
            const Align(
              alignment: AlignmentDirectional.centerStart,
              child: NestTag(
                label: NannyPickupCopy.changedToday,
                tone: NestTagTone.warning,
                icon: Icons.event_repeat,
              ),
            ),
          ],
          const SizedBox(height: NestSpace.lg),
          Text(NannyPickupCopy.checkDoorHint, style: nest.text.caption),
          const SizedBox(height: NestSpace.sm),
          NestButton(
            label: NannyPickupCopy.checkDoor,
            icon: Icons.doorbell_outlined,
            variant: NestButtonVariant.tonal,
            onPressed: onCheck,
          ),
        ],
      ),
    );
  }
}
