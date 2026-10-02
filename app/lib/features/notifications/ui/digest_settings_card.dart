import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/notifications_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../../../shared/ui/pick_minute_of_day.dart';
import '../../household/model/household_view.dart';
import '../model/digest_coverage.dart';
import '../model/notification_settings.dart';
import '../state/notification_settings_controller.dart';
import 'notification_look.dart';
import 'setting_switch_row.dart';
import 'setting_time_row.dart';

/// The morning digest's switch, its time on the household's clock, and — in
/// words — what this person's digest holds, which is what their grant lets
/// them see (notifications ADR-0002).
class DigestSettingsCard extends StatelessWidget {
  const DigestSettingsCard({required this.settings, super.key});

  final NotificationSettings settings;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final controller = context.read<NotificationSettingsController>();
    final view = context.watch<HouseholdView>();
    final coverage = digestCoverage(view.permissions);
    final digest = settings.digest;
    return NestCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SettingSwitchRow(
            icon: LucideIcons.sunset,
            tint: NestTileTint.butter,
            title: NotificationsCopy.digestSwitch,
            value: digest.enabled,
            onChanged: (on) => unawaited(controller.setDigest(enabled: on)),
          ),
          if (digest.enabled)
            SettingTimeRow(
              title: NotificationsCopy.digestTime,
              time: NestDates.timeOfDay(digest.minute),
              onTap: () => unawaited(_pickTime(context, controller)),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              NestSpace.lg,
              NestSpace.sm,
              NestSpace.lg,
              0,
            ),
            child: Text(
              NotificationsCopy.digestNote(view.household.timeZone),
              style: nest.text.caption,
            ),
          ),
          const SizedBox(height: NestSpace.lg),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: NestSpace.lg),
            child: Text(
              NotificationsCopy.digestHoldsTitle,
              style: nest.text.label,
            ),
          ),
          const SizedBox(height: NestSpace.sm),
          if (coverage.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: NestSpace.lg),
              child: Text(
                NotificationsCopy.digestHoldsNothing,
                style: nest.text.bodySecondary,
              ),
            ),
          if (coverage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: NestSpace.lg),
              child: Wrap(
                spacing: NestSpace.sm,
                runSpacing: NestSpace.sm,
                children: [
                  for (final kind in coverage)
                    NestTag(
                      icon: NotificationLook.sectionIcon(kind),
                      label: NotificationsCopy.coverageName(kind),
                      tone: NestTagTone.accent,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _pickTime(
    BuildContext context,
    NotificationSettingsController controller,
  ) async {
    final minute = await pickMinuteOfDay(
      context,
      initialMinutes: settings.digest.minute,
    );
    if (minute == null) return;
    await controller.setDigest(minute: minute);
  }
}
