import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../household/model/member.dart';

/// One booked shift: when, whose (for family), the note, whether it is on now,
/// and — for family — the way to cancel it.
class BookingRow extends StatelessWidget {
  const BookingRow({
    required this.when,
    required this.carer,
    required this.note,
    required this.isOnNow,
    required this.onCancel,
    super.key,
  });

  /// "Tomorrow, 17:30 – 22:00".
  final String when;

  /// Null on a carer's own list, where it is always them.
  final Member? carer;
  final String? note;
  final bool isOnNow;

  /// Null for anybody who may not cancel it.
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final person = carer;
    final cancel = onCancel;
    final lines = [if (person != null) when, ?note];
    return NestCard(
      variant: NestCardVariant.flat,
      padding: EdgeInsets.zero,
      child: NestListRow(
        leading: person == null
            ? const NestIconTile(
                icon: Icons.event_available_outlined,
                tint: NestTileTint.basil,
              )
            : NestAvatar(name: person.displayName, color: person.color),
        title: person == null ? when : person.displayName,
        subtitle: lines.isEmpty ? null : lines.join('\n'),
        footer: isOnNow
            ? const NestTag(
                label: NannyBookingCopy.onNow,
                tone: NestTagTone.success,
                icon: Icons.circle,
              )
            : null,
        trailing: cancel == null
            ? null
            : NestIconButton(
                icon: Icons.event_busy_outlined,
                label: NannyBookingCopy.cancel,
                variant: NestIconButtonVariant.plain,
                onPressed: cancel,
              ),
      ),
    );
  }
}
