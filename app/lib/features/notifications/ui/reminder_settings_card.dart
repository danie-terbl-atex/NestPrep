import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/notifications_copy.dart';
import '../../../shared/flags/feature_flag.dart';
import '../../../shared/flags/feature_flags_controller.dart';
import '../model/notification_settings.dart';
import '../model/notification_vocabulary.dart';
import '../state/notification_settings_controller.dart';
import 'notification_look.dart';
import 'setting_switch_row.dart';

/// The reminders a person can switch off one by one — switched off means not
/// sent at all, not even to the inbox (notifications ADR-0003). A V2
/// capability's switch shows only while that capability is on (foundation
/// ADR-0014).
class ReminderSettingsCard extends StatelessWidget {
  const ReminderSettingsCard({required this.settings, super.key});

  final NotificationSettings settings;

  @override
  Widget build(BuildContext context) {
    final controller = context.read<NotificationSettingsController>();
    final flags = context.watch<FeatureFlagsController>();
    bool offered(SwitchableCategory category) => switch (category) {
      SwitchableCategory.photos => flags.isOn(FeatureFlag.nannyPhotoUpdates),
      SwitchableCategory.coParenting => flags.isOn(FeatureFlag.coParenting),
      SwitchableCategory.documents ||
      SwitchableCategory.handover ||
      SwitchableCategory.chores => true,
    };
    return NestCard(
      padding: const EdgeInsets.symmetric(vertical: NestSpace.sm),
      child: Column(
        children: [
          for (final category in SwitchableCategory.values)
            if (offered(category))
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
