import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../../../shared/time/household_clock.dart';
import '../../subscriptions/ui/premium_mark.dart';
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
    this.sharingAlways = false,
    this.alwaysBusy = false,
    this.onAlways,
    this.onPause,
    this.onBatteryHelp,
    super.key,
  });

  /// Null when the signed-in account has claimed no profile in this household,
  /// which the household gate makes unreachable.
  final LocatedMember? viewer;

  final ValueChanged<ShareDuration> onShareFor;
  final VoidCallback onStop;

  /// This phone's always-on engine is reporting for this member.
  final bool sharingAlways;
  final bool alwaysBusy;
  final VoidCallback? onAlways;
  final VoidCallback? onPause;
  final VoidCallback? onBatteryHelp;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    if (sharingAlways) {
      return _AlwaysOnCard(
        busy: alwaysBusy,
        onPause: onPause,
        onBatteryHelp: onBatteryHelp,
      );
    }
    final sharingUntil = viewer?.isSharing ?? false
        ? viewer?.sharingUntil
        : null;
    final onAlways = this.onAlways;
    return NestCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(LocationCopy.yours, style: nest.text.title),
          const SizedBox(height: NestSpace.xs),
          Text(
            sharingUntil == null
                ? LocationCopy.yoursBody
                : _until(context, sharingUntil),
            style: nest.text.bodySecondary,
          ),
          const SizedBox(height: NestSpace.lg),
          if (sharingUntil == null)
            _ShareDurations(onShareFor: onShareFor)
          else
            NestButton(
              label: LocationCopy.stop,
              variant: NestButtonVariant.outline,
              icon: LucideIcons.mapPinOff,
              onPressed: onStop,
            ),
          if (onAlways != null && sharingUntil == null) ...[
            const SizedBox(height: NestSpace.lg),
            Row(
              children: [
                Expanded(
                  child: Text(
                    LocationCopy.alwaysBody,
                    style: nest.text.caption,
                  ),
                ),
                const SizedBox(width: NestSpace.sm),
                const PremiumMark(),
              ],
            ),
            const SizedBox(height: NestSpace.sm),
            NestButton(
              label: LocationCopy.always,
              variant: NestButtonVariant.tonal,
              icon: LucideIcons.radio,
              isLoading: alwaysBusy,
              onPressed: onAlways,
            ),
          ],
        ],
      ),
    );
  }

  /// The end of the window as a clock on the wall where the household lives,
  /// never where the device happens to be (`ENG-21`).
  String _until(BuildContext context, DateTime sharingUntil) {
    final clock = context.read<HouseholdClock>();
    final time = NestDates.timeOfDay(clock.minutesOfDay(sharingUntil));
    return '${LocationCopy.sharingUntil} $time';
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
        Text(LocationCopy.shareFor, style: nest.text.label),
        const SizedBox(height: NestSpace.sm),
        Wrap(
          spacing: NestSpace.sm,
          runSpacing: NestSpace.sm,
          children: [
            for (final duration in ShareDuration.values)
              NestChip(
                label: _label(duration),
                icon: LucideIcons.clock,
                onTap: () => onShareFor(duration),
              ),
          ],
        ),
      ],
    );
  }

  static String _label(ShareDuration duration) => switch (duration) {
    ShareDuration.fifteenMinutes => LocationCopy.fifteenMinutes,
    ShareDuration.oneHour => LocationCopy.oneHour,
    ShareDuration.fourHours => LocationCopy.fourHours,
  };
}

class _AlwaysOnCard extends StatelessWidget {
  const _AlwaysOnCard({
    required this.busy,
    required this.onPause,
    required this.onBatteryHelp,
  });

  final bool busy;
  final VoidCallback? onPause;
  final VoidCallback? onBatteryHelp;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final onBatteryHelp = this.onBatteryHelp;
    return NestCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(LocationCopy.alwaysOn, style: nest.text.title),
          const SizedBox(height: NestSpace.xs),
          Text(LocationCopy.alwaysOnBody, style: nest.text.bodySecondary),
          const SizedBox(height: NestSpace.lg),
          NestButton(
            label: LocationCopy.pause,
            variant: NestButtonVariant.outline,
            icon: LucideIcons.pause,
            isLoading: busy,
            onPressed: onPause,
          ),
          if (onBatteryHelp != null) ...[
            const SizedBox(height: NestSpace.sm),
            NestButton(
              label: LocationCopy.batteryHint,
              variant: NestButtonVariant.ghost,
              icon: LucideIcons.batteryWarning,
              onPressed: onBatteryHelp,
            ),
          ],
        ],
      ),
    );
  }
}
