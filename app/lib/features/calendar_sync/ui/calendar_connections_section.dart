import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/copy/calendar_sync_copy.dart';
import '../../household/model/household_view.dart';
import '../model/calendar_connection.dart';
import '../state/connected_calendars_controller.dart';
import 'calendar_connection_row.dart';

/// The household's connected calendars, in all four of their states
/// (`FE-08`). Only this part swaps: the ways to connect sit above it, outside,
/// so a household with nothing connected still has every way in.
class CalendarConnectionsSection extends StatelessWidget {
  const CalendarConnectionsSection({required this.onDisconnect, super.key});

  /// Asks before disconnecting; the screen owns the confirmation.
  final ValueChanged<CalendarConnection> onDisconnect;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ConnectedCalendarsController>();
    final view = context.read<HouseholdView>();
    final nest = NestTheme.of(context);
    return switch (controller.connections) {
      AsyncLoading() => const Column(
        children: [
          NestSkeleton(height: NestSize.controlLarge * 2),
          SizedBox(height: NestSpace.sm),
          NestSkeleton(height: NestSize.controlLarge * 2),
        ],
      ),
      AsyncFailure(:final failure) => NestErrorView(
        message: AppCopy.failure(failure),
        retryLabel: AppCopy.retry,
        onRetry: controller.retry,
      ),
      AsyncData(value: final connections) when connections.isEmpty => NestCard(
        variant: NestCardVariant.flat,
        padding: const EdgeInsets.all(NestSpace.lg),
        child: Row(
          children: [
            const NestIconTile(
              icon: Icons.event_note_outlined,
              tint: NestTileTint.sky,
              size: NestSize.avatarMedium,
              iconSize: NestSize.iconMedium,
            ),
            const SizedBox(width: NestSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    CalendarSyncCopy.emptyTitle,
                    style: nest.text.bodyStrong,
                  ),
                  const SizedBox(height: NestSpace.xxs),
                  Text(
                    CalendarSyncCopy.emptyBody,
                    style: nest.text.caption.copyWith(
                      color: nest.colors.inkSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      AsyncData(value: final connections) => Column(
        children: [
          for (final connection in connections)
            Padding(
              padding: const EdgeInsets.only(bottom: NestSpace.sm),
              child: CalendarConnectionRow(
                key: ValueKey(connection.id),
                connection: connection,
                owner: view.memberById(connection.memberId),
                sinceLastSync: controller.sinceLastSync(connection),
                canManage: controller.canManage(connection),
                isBusy: controller.isBusy(connection),
                onSyncNow: () => controller.syncNow(connection),
                onDisconnect: () => onDisconnect(connection),
              ),
            ),
        ],
      ),
    };
  }
}
