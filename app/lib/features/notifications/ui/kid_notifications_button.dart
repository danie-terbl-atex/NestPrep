import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/notifications_copy.dart';
import '../model/push_arrival.dart';
import '../state/push_registrar.dart';

/// A child's tablet turning reminders on — the phone's prompt behind a tap,
/// never at launch (notifications ADR-0003). What the tablet hears is the
/// parent's choice in the settings screen; this only lets it be reached.
class KidNotificationsButton extends StatelessWidget {
  const KidNotificationsButton({super.key});

  @override
  Widget build(BuildContext context) {
    final registrar = context.watch<PushRegistrar>();
    final isOn =
        registrar.permission == PushPermission.granted && registrar.isReachable;
    return NestIconButton(
      icon: isOn ? LucideIcons.bellRing : LucideIcons.bellOff,
      label: isOn ? NotificationsCopy.kidOn : NotificationsCopy.kidTurnOn,
      variant: NestIconButtonVariant.plain,
      onPressed: isOn || registrar.isAsking
          ? null
          : () => unawaited(registrar.turnOn()),
    );
  }
}
