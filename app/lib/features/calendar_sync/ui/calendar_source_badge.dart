import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/calendar_sync_copy.dart';
import '../model/calendar_provider.dart';
import 'calendar_source_look.dart';

/// The small pill on an imported event that says where it came from —
/// "Google", "Outlook", "Apple" — so a read-only event is never mistaken for
/// one the household can edit (calendar ADR-0003). Icon and word together;
/// the tint alone would say nothing (`FE-13`).
class CalendarSourceBadge extends StatelessWidget {
  const CalendarSourceBadge({
    required this.provider,
    this.label = '',
    super.key,
  });

  final CalendarProvider provider;

  /// The connection's account label, which tells an iCloud link apart.
  final String label;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final look = CalendarSourceLook.of(provider, label: label);
    final fill = switch (look.tint) {
      NestTileTint.accent => nest.colors.accentSoft,
      NestTileTint.guava => nest.colors.tileGuava,
      NestTileTint.basil => nest.colors.tileBasil,
      NestTileTint.lilac => nest.colors.tileLilac,
      NestTileTint.butter => nest.colors.tileButter,
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(NestRadius.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: NestSpace.sm,
          vertical: NestSpace.xxs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              look.icon,
              size: NestSize.iconSmall,
              color: nest.colors.accentInk,
            ),
            const SizedBox(width: NestSpace.xs),
            Flexible(
              child: Text(
                CalendarSyncCopy.sourceName(provider, label: label),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: nest.text.caption.copyWith(color: nest.colors.accentInk),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
