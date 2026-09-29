import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/notifications_copy.dart';
import '../model/notification_settings.dart';
import '../model/notification_vocabulary.dart';
import '../state/notification_settings_controller.dart';
import 'notification_look.dart';
import 'setting_switch_row.dart';

/// The reminders a person can switch off one by one — switched off means not
/// sent at all, not even to the inbox (notifications ADR-0003).
class ReminderSettingsCard extends StatelessWidget {
  const ReminderSettingsCard({required this.settings, super.key});

  final NotificationSettings settings;

  @override
  Widget build(BuildContext context) {
    final controller = context.read<NotificationSettingsController>();
    return NestCard(
      padding: const EdgeInsets.symmetric(vertical: NestSpace.sm),
      child: Column(
        children: [
          for (final category in SwitchableCategory.values)
            SettingSwitchRow(
              key: ValueKey('reminder-${category.name}'),
              icon: NotificationLook.switchableIcon(category),
              tint: NestTileTint.mint,
              title: NotificationsCopy.categorySwitch(category),
              subtitle: NotificationsCopy.categoryHint(category),
              value: settings.wants(category),
              onChanged: (on) =>
                  unawaited(controller.setCategory(category, on)),
            ),
        ],
      ),
    );
  }
}
