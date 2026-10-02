import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/calendar_sync_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../../household/model/member.dart';
import '../model/calendar_connection.dart';
import 'calendar_source_look.dart';

/// One connected calendar: whose it is, what it is, and how its last sync went
/// — in words, with a warning tone when something needs doing (`FE-09`). The
/// owner and an admin get "Sync now" and "Disconnect"; everybody else sees it
/// and nothing to press, which is what the Functions allow (calendar
/// ADR-0003).
class CalendarConnectionRow extends StatelessWidget {
  const CalendarConnectionRow({
    required this.connection,
    required this.owner,
    required this.sinceLastSync,
    required this.canManage,
    required this.isBusy,
    required this.onSyncNow,
    required this.onDisconnect,
    super.key,
  });

  final CalendarConnection connection;

  /// Null when the profile has since been removed from the household.
  final Member? owner;
  final Duration? sinceLastSync;
  final bool canManage;
  final bool isBusy;
  final VoidCallback onSyncNow;
  final VoidCallback onDisconnect;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final look = CalendarSourceLook.of(
      connection.provider,
      label: connection.accountLabel,
    );
    final isHealthy = connection.status.isHealthy;
    final age = sinceLastSync;
    return NestCard(
      variant: NestCardVariant.flat,
      padding: const EdgeInsets.all(NestSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              owner == null
                  ? NestIconTile(
                      icon: look.icon,
                      tint: look.tint,
                      size: NestSize.avatarMedium,
                      iconSize: NestSize.iconMedium,
                    )
                  : NestAvatar(name: owner!.displayName, color: owner!.color),
              const SizedBox(width: NestSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      CalendarSyncCopy.connectionTitle(
                        owner?.displayName ?? CalendarSyncCopy.formerMember,
                        connection.provider,
                        label: connection.accountLabel,
                      ),
                      style: nest.text.bodyStrong.copyWith(
                        color: nest.colors.ink,
                      ),
                    ),
                    if (connection.accountLabel.isNotEmpty)
                      Text(
                        connection.accountLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: nest.text.caption.copyWith(
                          color: nest.colors.inkTertiary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: NestSpace.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                isHealthy ? LucideIcons.circleCheck : LucideIcons.circleAlert,
                size: NestSize.iconSmall,
                color: isHealthy ? nest.colors.success : nest.colors.warning,
              ),
              const SizedBox(width: NestSpace.sm),
              Expanded(
                child: Text(
                  CalendarSyncCopy.status(
                    connection.status,
                    syncedAgo: age == null ? null : NestDates.ago(age),
                    eventCount: connection.eventCount,
                  ),
                  style: nest.text.caption.copyWith(
                    color: isHealthy
                        ? nest.colors.inkSecondary
                        : nest.colors.warning,
                  ),
                ),
              ),
            ],
          ),
          if (canManage) ...[
            const SizedBox(height: NestSpace.md),
            Wrap(
              spacing: NestSpace.sm,
              runSpacing: NestSpace.sm,
              children: [
                NestButton(
                  label: CalendarSyncCopy.syncNow,
                  icon: LucideIcons.refreshCw,
                  variant: NestButtonVariant.tonal,
                  size: NestButtonSize.small,
                  isExpanded: false,
                  isLoading: isBusy,
                  onPressed: isBusy ? null : onSyncNow,
                ),
                NestButton(
                  label: CalendarSyncCopy.disconnect,
                  icon: LucideIcons.unlink,
                  variant: NestButtonVariant.ghost,
                  size: NestButtonSize.small,
                  isExpanded: false,
                  onPressed: isBusy ? null : onDisconnect,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
