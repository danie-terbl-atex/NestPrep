import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/notifications_copy.dart';
import '../model/push_arrival.dart';
import '../state/notification_settings_controller.dart';
import '../state/push_registrar.dart';
import 'push_permission_card.dart';

/// This phone's part of the settings (notifications ADR-0003): turning
/// notifications on while they are off, and — once they are on — saying so,
/// with a test push to prove it.
class PhoneSettingsCard extends StatelessWidget {
  const PhoneSettingsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final registrar = context.watch<PushRegistrar>();
    final controller = context.watch<NotificationSettingsController>();
    if (registrar.permission != PushPermission.granted ||
        !registrar.isReachable) {
      return PushPermissionCard(
        permission: registrar.permission,
        isReachable: registrar.isReachable,
        isAsking: registrar.isAsking,
        onTurnOn: () => unawaited(controller.turnOn()),
      );
    }
    final nest = NestTheme.of(context);
    final outcome = controller.testOutcome;
    return NestCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const NestToneRow(
            icon: Icons.notifications_active_rounded,
            title: NotificationsCopy.onMessage,
            tone: NestTagTone.success,
          ),
          const SizedBox(height: NestSpace.lg),
          NestButton(
            label: NotificationsCopy.sendTest,
            variant: NestButtonVariant.tonal,
            icon: Icons.send_rounded,
            isLoading: controller.isSendingTest,
            onPressed: () => unawaited(controller.sendTest()),
          ),
          if (outcome != null) ...[
            const SizedBox(height: NestSpace.md),
            Semantics(
              liveRegion: true,
              child: Text(
                NotificationsCopy.testOutcome(outcome),
                style: nest.text.bodySecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
