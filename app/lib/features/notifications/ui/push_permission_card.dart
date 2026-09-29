import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/notifications_copy.dart';
import '../model/push_arrival.dart';

/// Where a person turns notifications on — saying first what they would get,
/// then asking the phone (notifications ADR-0003: never at launch). Refused,
/// it says where the switch is now; allowed but unreachable, it says the phone
/// cannot be reached yet, rather than pretending.
class PushPermissionCard extends StatelessWidget {
  const PushPermissionCard({
    required this.permission,
    required this.isReachable,
    required this.isAsking,
    required this.onTurnOn,
    super.key,
  });

  final PushPermission permission;
  final bool isReachable;
  final bool isAsking;
  final VoidCallback onTurnOn;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return NestCard(
      variant: NestCardVariant.tinted,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const NestIconTile(
                icon: Icons.notifications_active_outlined,
                tint: NestTileTint.peach,
                size: NestSize.avatarMedium,
                iconSize: NestSize.iconMedium,
              ),
              const SizedBox(width: NestSpace.lg),
              Expanded(
                child: Text(
                  NotificationsCopy.turnOnTitle,
                  style: nest.text.title,
                ),
              ),
            ],
          ),
          const SizedBox(height: NestSpace.md),
          Text(_message, style: nest.text.bodySecondary),
          if (_canAsk) ...[
            const SizedBox(height: NestSpace.lg),
            NestButton(
              label: NotificationsCopy.turnOn,
              icon: Icons.notifications_rounded,
              isLoading: isAsking,
              onPressed: onTurnOn,
            ),
          ],
        ],
      ),
    );
  }

  bool get _canAsk =>
      permission == PushPermission.notAsked ||
      permission == PushPermission.unknown;

  String get _message => switch (permission) {
    PushPermission.denied => NotificationsCopy.deniedMessage,
    PushPermission.granted when !isReachable =>
      NotificationsCopy.unreachableMessage,
    _ => NotificationsCopy.turnOnMessage,
  };
}
