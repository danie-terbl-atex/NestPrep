import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/notifications_copy.dart';
import '../state/notification_settings_controller.dart';
import 'setting_switch_row.dart';

/// Each child's morning digest, for family to switch on or off — the one
/// place a person decides for somebody else (notifications ADR-0003). A
/// child's tablet only ever hears about their own lunch and chores.
class KidsNotificationsCard extends StatelessWidget {
  const KidsNotificationsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final controller = context.watch<NotificationSettingsController>();
    return NestCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final kid in controller.kids)
            SettingSwitchRow(
              key: ValueKey('kid-digest-${kid.id}'),
              icon: Icons.child_care_outlined,
              tint: NestTileTint.guava,
              title: kid.displayName,
              subtitle: NotificationsCopy.kidDigest,
              value: controller.kidSettings(kid.id).digest.enabled,
              onChanged: (on) => unawaited(controller.setKidDigest(kid.id, on)),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              NestSpace.lg,
              NestSpace.sm,
              NestSpace.lg,
              0,
            ),
            child: Text(NotificationsCopy.kidsNote, style: nest.text.caption),
          ),
        ],
      ),
    );
  }
}
