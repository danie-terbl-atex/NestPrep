import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/kid_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../../../shared/time/calendar_date.dart';
import '../model/kid_device.dart';

/// One device a child is signed in on, with the way to sign it out
/// (accounts ADR-0003). The label is what the parent called it when they made
/// the code; a device nobody named is told apart by when it was paired.
class KidDeviceRow extends StatelessWidget {
  const KidDeviceRow({
    required this.device,
    required this.pairedOn,
    required this.today,
    required this.onRevoke,
    super.key,
  });

  final KidDevice device;

  /// The household's day the device was paired on, or null while the server
  /// has not stamped it yet.
  final CalendarDate? pairedOn;
  final CalendarDate today;
  final VoidCallback onRevoke;

  @override
  Widget build(BuildContext context) {
    final day = pairedOn;
    return NestListRow(
      leading: const NestIconTile(
        icon: Icons.tablet_android_rounded,
        tint: NestTileTint.mint,
      ),
      title: device.label.isEmpty ? KidCopy.manageUnnamedDevice : device.label,
      subtitle: day == null
          ? null
          : KidCopy.managePairedOn(NestDates.full(day, today)),
      trailing: NestIconButton(
        icon: Icons.logout_rounded,
        label: KidCopy.manageRevoke,
        variant: NestIconButtonVariant.plain,
        onPressed: onRevoke,
      ),
    );
  }
}
