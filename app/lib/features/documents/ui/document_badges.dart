import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/time/calendar_date.dart';
import '../model/expiry_schedule.dart';
import 'expiry_badge.dart';

/// The badges under a document's name: when it expires, then its tags. Empty
/// — and taking no space — for a document with neither.
class DocumentBadges extends StatelessWidget {
  const DocumentBadges({
    required this.expiresOn,
    required this.tags,
    required this.today,
    super.key,
  });

  final CalendarDate? expiresOn;
  final List<String> tags;
  final CalendarDate today;

  /// Whether there is anything to show, so a row can leave its footer out.
  static bool hasAny({
    required CalendarDate? expiresOn,
    required List<String> tags,
  }) => expiresOn != null || tags.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: NestSpace.xs,
      runSpacing: NestSpace.xs,
      children: [
        if (expiresOn != null)
          ExpiryBadge(
            status: ExpirySchedule.statusOf(expiresOn, today),
            today: today,
          ),
        for (final tag in tags)
          NestBadge(label: tag, icon: Icons.sell_outlined),
      ],
    );
  }
}
