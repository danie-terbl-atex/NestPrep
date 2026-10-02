import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/notifications_route.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/copy/notifications_copy.dart';
import '../../../shared/time/household_clock.dart';
import '../../../shared/ui/back_leading.dart';
import '../../household/model/household_view.dart';
import '../data/notification_repository.dart';
import '../model/inbox_groups.dart';
import '../model/inbox_item.dart';
import '../model/notification_vocabulary.dart';
import '../model/push_arrival.dart';
import '../state/inbox_controller.dart';
import '../state/push_registrar.dart';
import '../state/turn_on_notifications.dart';
import 'inbox_row.dart';
import 'push_permission_card.dart';

/// A person's notifications (notifications ADR-0001): everything they were
/// sent, newest first, today apart from before. Pushed from the bell in every
/// tab's header, so it carries its own way back (`FE-17`).
///
/// The card that turns notifications on leads both the list and the empty
/// state, and scrolls with them — an empty inbox still has its way in
/// (`FE-08`), and at 200% text the card never pushes the list off the phone
/// (`FE-14`).
class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<InboxController>();
    final failure = controller.actionFailure;
    return NestScaffold(
      title: NotificationsCopy.inboxTitle,
      leading: backLeading(context),
      trailing: [
        if (controller.hasUnread)
          NestIconButton(
            icon: LucideIcons.checkCheck,
            label: NotificationsCopy.markAllRead,
            variant: NestIconButtonVariant.plain,
            onPressed: controller.markAllRead,
          ),
        NestIconButton(
          icon: LucideIcons.slidersHorizontal,
          label: NotificationsCopy.settingsLabel,
          onPressed: () => context.push(
            NotificationsRoute.settingsPathFor(controller.householdId),
          ),
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (failure != null)
            Padding(
              padding: const EdgeInsets.only(bottom: NestSpace.lg),
              child: NestBanner(
                message: AppCopy.failure(failure),
                tone: NestBannerTone.danger,
                actionLabel: AppCopy.back,
                onAction: controller.dismissActionFailure,
              ),
            ),
          Expanded(
            child: NestAsyncView<List<InboxItem>>(
              state: controller.items,
              isEmpty: (items) => items.isEmpty,
              onRetry: controller.retry,
              emptyBuilder: (_) => ListView(
                children: const [
                  _TurnOnCard(),
                  NestEmptyView(
                    title: NotificationsCopy.emptyTitle,
                    message: NotificationsCopy.emptyMessage,
                    icon: LucideIcons.sunset,
                  ),
                ],
              ),
              dataBuilder: (context, items) =>
                  _InboxList(items: items, controller: controller),
            ),
          ),
        ],
      ),
    );
  }
}

/// The way to turn notifications on, while they are off or the phone cannot
/// be reached — and nothing at all once they work.
class _TurnOnCard extends StatelessWidget {
  const _TurnOnCard();

  @override
  Widget build(BuildContext context) {
    final registrar = context.watch<PushRegistrar>();
    if (registrar.permission == PushPermission.granted &&
        registrar.isReachable) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: NestSpace.lg),
      child: NestRiseIn(
        child: PushPermissionCard(
          permission: registrar.permission,
          isReachable: registrar.isReachable,
          isAsking: registrar.isAsking,
          onTurnOn: () => unawaited(_turnOn(context)),
        ),
      ),
    );
  }

  Future<void> _turnOn(BuildContext context) async {
    final view = context.read<HouseholdView>();
    await turnOnNotifications(
      registrar: context.read<PushRegistrar>(),
      repository: context.read<NotificationRepository>(),
      owner: NotificationsOwner(
        householdId: view.household.id,
        memberId: view.viewerMember?.id ?? '',
        isFamily: view.permissions.isFamily,
      ),
    );
  }
}

class _InboxList extends StatelessWidget {
  const _InboxList({required this.items, required this.controller});

  final List<InboxItem> items;
  final InboxController controller;

  @override
  Widget build(BuildContext context) {
    final clock = context.read<HouseholdClock>();
    final groups = InboxGroups.of(items, clock);
    var index = 0;
    Widget rowFor(InboxItem item) => Padding(
      key: ValueKey('inbox-${item.id}'),
      padding: const EdgeInsets.only(bottom: NestSpace.xs),
      child: NestRiseIn(
        index: index++,
        child: InboxRow(
          item: item,
          when: InboxGroups.whenOf(item, clock),
          onOpen: () => _open(context, item),
          onClear: () => unawaited(controller.clear(item)),
        ),
      ),
    );
    return ListView(
      padding: const EdgeInsets.only(bottom: NestSpace.huge),
      children: [
        const _TurnOnCard(),
        if (groups.today.isNotEmpty) ...[
          const NestSectionHeader(title: NotificationsCopy.today),
          const SizedBox(height: NestSpace.sm),
          for (final item in groups.today) rowFor(item),
          const SizedBox(height: NestSpace.xl),
        ],
        if (groups.earlier.isNotEmpty) ...[
          const NestSectionHeader(title: NotificationsCopy.earlier),
          const SizedBox(height: NestSpace.sm),
          for (final item in groups.earlier) rowFor(item),
        ],
      ],
    );
  }

  void _open(BuildContext context, InboxItem item) {
    final householdId = controller.householdId;
    // A digest, or a notification about nothing but itself, opens here; the
    // rest go where they are about (ADR-0001).
    if (item.target.target == NotificationTarget.inboxItem) {
      unawaited(
        context.push(NotificationsRoute.itemPathFor(householdId, item.id)),
      );
      return;
    }
    unawaited(controller.markRead(item));
    unawaited(
      context.push(
        NotificationsRoute.targetPath(
          householdId: householdId,
          inboxId: item.id,
          target: item.target.target,
          targetId: item.target.id,
        ),
      ),
    );
  }
}
