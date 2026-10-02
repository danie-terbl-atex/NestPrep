import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../model/calendar_provider.dart';

/// How each source of events looks, in one place, so the connect row, the
/// connection row and an imported event's badge can never disagree
/// (`ENG-01`). The tint is decorative; the name beside it is the signal
/// (`FE-13`). Brand marks are deliberately not drawn — they are not ours.
final class CalendarSourceLook {
  const CalendarSourceLook._(this.icon, this.tint);

  final IconData icon;
  final NestTileTint tint;

  static CalendarSourceLook of(
    CalendarProvider provider, {
    String label = '',
  }) => switch (provider) {
    CalendarProvider.google => const CalendarSourceLook._(
      LucideIcons.calendarDays,
      NestTileTint.lilac,
    ),
    CalendarProvider.microsoft => const CalendarSourceLook._(
      LucideIcons.briefcase,
      NestTileTint.accent,
    ),
    CalendarProvider.ics =>
      label.contains('icloud.com')
          ? const CalendarSourceLook._(LucideIcons.cloud, NestTileTint.basil)
          : const CalendarSourceLook._(LucideIcons.link, NestTileTint.butter),
  };
}
