import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../household/model/member.dart';

/// One carer on the booked-shifts screen, and whether they are kept to their
/// booked shifts (nanny-hub ADR-0006). An admin flips it; everybody else reads
/// it. The switch waits while a change is on its way (`FE-10`).
class CarerAccessRow extends StatelessWidget {
  const CarerAccessRow({
    required this.carer,
    required this.isShiftOnly,
    required this.isChanging,
    required this.onChanged,
    super.key,
  });

  final Member carer;
  final bool isShiftOnly;
  final bool isChanging;

  /// Null for a viewer who may not change it — anybody but an admin.
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final change = onChanged;
    return NestCard(
      variant: NestCardVariant.flat,
      padding: EdgeInsets.zero,
      child: NestListRow(
        leading: NestAvatar(name: carer.displayName, color: carer.color),
        title: carer.displayName,
        subtitle: [
          isShiftOnly
              ? NannyBookingCopy.shiftOnlyOn
              : NannyBookingCopy.shiftOnlyOff,
          if (change == null) NannyBookingCopy.shiftOnlyAdminOnly,
        ].join(' '),
        footer: Row(
          children: [
            Expanded(
              child: ExcludeSemantics(
                child: Text(
                  NannyBookingCopy.shiftOnly,
                  style: NestTheme.of(context).text.bodyStrong,
                ),
              ),
            ),
            Semantics(
              label: NannyBookingCopy.shiftOnlyFor(carer.displayName),
              child: Switch(
                value: isShiftOnly,
                onChanged: change == null || isChanging ? null : change,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
