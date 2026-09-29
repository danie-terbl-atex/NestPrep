import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/vault_copy.dart';
import '../../../shared/time/calendar_date.dart';
import '../model/document_entry.dart';
import '../model/expiry_schedule.dart';
import 'expiry_badge.dart';

/// The papers that need renewing soon — expired, due today, or inside the
/// thirty-day reminder — the most urgent first, and a way to all of them
/// (documents ADR-0005). The in-app half of the reminders the server writes.
///
/// It shows nothing at all when nothing needs attention; an empty "expiring
/// soon" card is noise on the screen people open to find a paper.
class ExpiringSoonCard extends StatelessWidget {
  const ExpiringSoonCard({
    required this.entries,
    required this.today,
    required this.onOpen,
    required this.onSeeAll,
    this.ownerNames = const {},
    super.key,
  });

  /// Already filtered to what needs attention, most urgent first.
  final List<DocumentEntry> entries;
  final CalendarDate today;
  final ValueChanged<DocumentEntry> onOpen;
  final VoidCallback onSeeAll;

  /// Whose vault each entry is in, by member id.
  final Map<String, String> ownerNames;

  /// How many rows before "See all" takes over.
  static const shown = 3;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();
    return NestCard(
      variant: NestCardVariant.tinted,
      padding: const EdgeInsets.all(NestSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NestSectionHeader(
            title: VaultCopy.expiringTitle,
            actionLabel: entries.length > shown
                ? VaultCopy.expiringSeeAll
                : null,
            onAction: entries.length > shown ? onSeeAll : null,
          ),
          for (final entry in entries.take(shown))
            NestListRow(
              key: ValueKey('${entry.ownerMemberId}/${entry.id}'),
              title: entry.name,
              subtitle: ownerNames[entry.ownerMemberId],
              leading: const NestIconTile(
                icon: Icons.event_busy_outlined,
                tint: NestTileTint.peach,
                size: NestSize.avatarMedium,
                iconSize: NestSize.iconMedium,
              ),
              footer: ExpiryBadge(
                status: ExpirySchedule.statusOf(entry.expiresOn, today),
                today: today,
              ),
              onTap: () => onOpen(entry),
            ),
        ],
      ),
    );
  }
}
