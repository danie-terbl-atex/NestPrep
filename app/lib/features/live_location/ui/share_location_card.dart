import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../../../shared/time/household_clock.dart';
import '../model/located_member.dart';
import '../model/share_duration.dart';

/// The one control on this screen, and the only place in the app that asks
/// anybody for their position.
///
/// It is the person's own state and their own decision: an admin looking at
/// this screen sees their own card, never somebody else's, because there is no
/// rule that would let them write anybody else's document (live-location
/// ADR-0002). It is always on the screen, whether or not anybody is sharing —
/// a control that disappears with the empty state is a way in that is gone
/// exactly when it is needed.
class ShareLocationCard extends StatelessWidget {
  const ShareLocationCard({
    required this.viewer,
    required this.onShareFor,
    required this.onStop,
    super.key,
  });

  /// Null when the signed-in account has claimed no profile in this household,
  /// which the household gate makes unreachable.
  final LocatedMember? viewer;

  final ValueChanged<ShareDuration> onShareFor;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final sharingUntil = viewer?.isSharing ?? false
        ? viewer?.sharingUntil
        : null;
    return NestCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppCopy.locationYours, style: nest.text.title),
          const SizedBox(height: NestSpace.xs),
          Text(
            sharingUntil == null
                ? AppCopy.locationYoursBody
                : _until(context, sharingUntil),
            style: nest.text.bodySecondary,
          ),
          const SizedBox(height: NestSpace.lg),
          if (sharingUntil == null)
            _ShareDurations(onShareFor: onShareFor)
          else
            NestButton(
              label: AppCopy.locationStop,
              variant: NestButtonVariant.outline,
              icon: Icons.location_off_outlined,
              onPressed: onStop,
            ),
        ],
      ),
    );
  }

  /// The end of the window as a clock on the wall where the household lives,
  /// never where the device happens to be (`ENG-21`).
  String _until(BuildContext context, DateTime sharingUntil) {
    final clock = context.read<HouseholdClock>();
    final time = NestDates.timeOfDay(clock.minutesOfDay(sharingUntil));
    return '${AppCopy.locationSharingUntil} $time';
  }
}

/// How long, offered as the three answers a household actually gives: the
/// school run, the trip, the day out (live-location ADR-0002).
class _ShareDurations extends StatelessWidget {
  const _ShareDurations({required this.onShareFor});

  final ValueChanged<ShareDuration> onShareFor;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppCopy.locationShareFor, style: nest.text.label),
        const SizedBox(height: NestSpace.sm),
        Wrap(
          spacing: NestSpace.sm,
          runSpacing: NestSpace.sm,
          children: [
            for (final duration in ShareDuration.values)
              NestChip(
                label: _label(duration),
                icon: Icons.schedule,
                onTap: () => onShareFor(duration),
              ),
          ],
        ),
      ],
    );
  }

  static String _label(ShareDuration duration) => switch (duration) {
    ShareDuration.fifteenMinutes => AppCopy.locationFifteenMinutes,
    ShareDuration.oneHour => AppCopy.locationOneHour,
    ShareDuration.fourHours => AppCopy.locationFourHours,
  };
}
