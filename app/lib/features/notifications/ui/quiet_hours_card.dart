import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/notifications_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../../../shared/ui/pick_minute_of_day.dart';
import '../model/notification_settings.dart';
import '../state/notification_settings_controller.dart';
import 'setting_switch_row.dart';
import 'setting_time_row.dart';

/// When pushes wait for the morning: the switch, and the two ends of the
/// night on the household's clock. The inbox has everything at once either
/// way (notifications ADR-0001).
class QuietHoursCard extends StatelessWidget {
  const QuietHoursCard({required this.settings, super.key});

  final NotificationSettings settings;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final controller = context.read<NotificationSettingsController>();
    final quiet = settings.quietHours;
    return NestCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SettingSwitchRow(
            icon: LucideIcons.moon,
            tint: NestTileTint.lilac,
            title: NotificationsCopy.quietSwitch,
            value: quiet.enabled,
            onChanged: (on) => unawaited(controller.setQuietHours(enabled: on)),
          ),
          if (quiet.enabled) ...[
            SettingTimeRow(
              title: NotificationsCopy.quietFrom,
              time: NestDates.timeOfDay(quiet.startMinute),
              onTap: () => unawaited(
                _pick(context, quiet.startMinute, (minute) {
                  return controller.setQuietHours(start: minute);
                }),
              ),
            ),
            SettingTimeRow(
              title: NotificationsCopy.quietUntil,
              time: NestDates.timeOfDay(quiet.endMinute),
              onTap: () => unawaited(
                _pick(context, quiet.endMinute, (minute) {
                  return controller.setQuietHours(end: minute);
                }),
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(
              NestSpace.lg,
              NestSpace.sm,
              NestSpace.lg,
              0,
            ),
            child: Text(NotificationsCopy.quietNote, style: nest.text.caption),
          ),
        ],
      ),
    );
  }

  static Future<void> _pick(
    BuildContext context,
    int initial,
    Future<void> Function(int minute) save,
  ) async {
    final minute = await pickMinuteOfDay(context, initialMinutes: initial);
    if (minute == null) return;
    await save(minute);
  }
}
