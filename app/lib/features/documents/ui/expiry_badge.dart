import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/vault_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../../../shared/time/calendar_date.dart';
import '../model/expiry_status.dart';

/// How near a document is to expiring, as words and an icon and a tone —
/// never the tone alone (`FE-13`). Nothing at all for a document with no
/// expiry date.
class ExpiryBadge extends StatelessWidget {
  const ExpiryBadge({required this.status, required this.today, super.key});

  final ExpiryStatus status;
  final CalendarDate today;

  @override
  Widget build(BuildContext context) {
    final date = status.date;
    final daysLeft = status.daysLeft;
    if (date == null || daysLeft == null) return const SizedBox.shrink();
    final (label, tone, icon) = switch (status.urgency) {
      ExpiryUrgency.expired => (
        VaultCopy.expired,
        NestBadgeTone.danger,
        LucideIcons.circleAlert,
      ),
      ExpiryUrgency.today => (
        VaultCopy.expiresToday,
        NestBadgeTone.danger,
        LucideIcons.calendarX,
      ),
      ExpiryUrgency.soon => (
        VaultCopy.expiresIn(daysLeft),
        NestBadgeTone.warning,
        LucideIcons.clock,
      ),
      ExpiryUrgency.comingUp => (
        VaultCopy.expiresOn(NestDates.full(date, today)),
        NestBadgeTone.info,
        LucideIcons.calendarDays,
      ),
      ExpiryUrgency.later || ExpiryUrgency.none => (
        VaultCopy.expiresOn(NestDates.full(date, today)),
        NestBadgeTone.neutral,
        LucideIcons.calendarDays,
      ),
    };
    return NestBadge(label: label, tone: tone, icon: icon);
  }
}
