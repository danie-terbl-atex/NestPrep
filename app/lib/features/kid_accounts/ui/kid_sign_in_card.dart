import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/kid_copy.dart';
import '../../../shared/time/household_clock.dart';
import '../model/kid_device.dart';
import '../model/kid_sign_in_entry.dart';
import 'kid_device_row.dart';

/// One child on the parent's kid sign-in screen: who, where they are signed in,
/// and the two things a parent does about it — add a device, or end them all
/// (accounts ADR-0003).
class KidSignInCard extends StatelessWidget {
  const KidSignInCard({
    required this.entry,
    required this.clock,
    required this.onAddDevice,
    required this.onRevoke,
    required this.onSignOutEverywhere,
    super.key,
  });

  final KidSignInEntry entry;
  final HouseholdClock clock;
  final VoidCallback onAddDevice;
  final ValueChanged<KidDevice> onRevoke;
  final VoidCallback onSignOutEverywhere;

  @override
  Widget build(BuildContext context) {
    final member = entry.member;
    final devices = entry.devices;
    final today = clock.today;
    return NestCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NestListRow(
            leading: NestAvatar(name: member.displayName, color: member.color),
            title: member.displayName,
            subtitle: devices.isEmpty
                ? KidCopy.manageNoDevices
                : KidCopy.manageDeviceCount(devices.length),
          ),
          for (final device in devices)
            KidDeviceRow(
              key: ValueKey(device.id),
              device: device,
              pairedOn: switch (device.pairedAt) {
                final pairedAt? => clock.dateOf(pairedAt),
                null => null,
              },
              today: today,
              onRevoke: () => onRevoke(device),
            ),
          const SizedBox(height: NestSpace.md),
          NestButton(
            label: KidCopy.manageAddDevice,
            icon: LucideIcons.plus,
            variant: NestButtonVariant.tonal,
            size: NestButtonSize.medium,
            onPressed: entry.canAddDevice ? onAddDevice : null,
          ),
          if (devices.isNotEmpty) ...[
            const SizedBox(height: NestSpace.sm),
            NestButton(
              label: KidCopy.manageSignOutEverywhere,
              icon: LucideIcons.smartphone,
              variant: NestButtonVariant.ghost,
              size: NestButtonSize.medium,
              onPressed: onSignOutEverywhere,
            ),
          ],
        ],
      ),
    );
  }
}
