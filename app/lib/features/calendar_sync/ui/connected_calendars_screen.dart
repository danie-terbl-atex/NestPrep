import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/copy/calendar_sync_copy.dart';
import '../../accounts/ui/account_menu_button.dart';
import '../state/connected_calendars_controller.dart';
import 'calendar_connect_list.dart';
import 'calendar_connections_section.dart';
import 'calendar_feed_card.dart';

/// Connected calendars (calendar ADR-0003): bring Google, Outlook or Apple in,
/// see how each connection is doing, and take the family week out as a feed.
/// Reached from the week's header; it pushes, so back returns to the week
/// (`FE-17`).
class ConnectedCalendarsScreen extends StatelessWidget {
  const ConnectedCalendarsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ConnectedCalendarsController>();
    final nest = NestTheme.of(context);
    return NestScaffold(
      title: CalendarSyncCopy.title,
      subtitle: CalendarSyncCopy.subtitle,
      leading: context.canPop()
          ? NestIconButton(
              icon: LucideIcons.arrowLeft,
              label: AppCopy.back,
              variant: NestIconButtonVariant.plain,
              onPressed: context.pop,
            )
          : null,
      trailing: const [AccountMenuButton()],
      body: ListView(
        padding: const EdgeInsets.only(bottom: NestSpace.huge),
        children: [
          const CalendarConnectBanners(),
          // Connecting brings a calendar into the family week: `edit` on the
          // calendar (household ADR-0003).
          if (controller.canConnect) ...[
            const NestSectionHeader(title: CalendarSyncCopy.sectionConnect),
            const SizedBox(height: NestSpace.sm),
            const NestRiseIn(child: CalendarConnectList()),
            const SizedBox(height: NestSpace.sm),
            Text(
              CalendarSyncCopy.privacyNote,
              style: nest.text.caption.copyWith(color: nest.colors.inkTertiary),
            ),
            const SizedBox(height: NestSpace.xxl),
          ],
          const NestSectionHeader(title: CalendarSyncCopy.sectionConnected),
          const SizedBox(height: NestSpace.sm),
          NestRiseIn(
            index: 1,
            child: CalendarConnectionsSection(
              onDisconnect: (connection) =>
                  confirmDisconnect(context, controller, connection),
              onChooseCalendars: () =>
                  chooseAppleCalendars(context, controller),
            ),
          ),
          const SizedBox(height: NestSpace.xxl),
          const NestSectionHeader(title: CalendarSyncCopy.sectionShare),
          const SizedBox(height: NestSpace.sm),
          NestRiseIn(
            index: 2,
            child: CalendarFeedCard(
              feed: controller.feed,
              isBusy: controller.isSharingFeed,
              canReset: controller.isAdmin,
              onGetLink: controller.shareFeed,
              onSubscribe: controller.subscribeToFeed,
              onReset: () => _resetFeed(context, controller),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _resetFeed(
    BuildContext context,
    ConnectedCalendarsController controller,
  ) async {
    final confirmed = await showNestConfirm(
      context: context,
      title: CalendarSyncCopy.feedResetConfirm,
      message: CalendarSyncCopy.feedResetBody,
      confirmLabel: CalendarSyncCopy.feedReset,
      cancelLabel: AppCopy.householdCancel,
      isDangerous: true,
    );
    if (confirmed != true) return;
    await controller.resetFeed();
  }
}
