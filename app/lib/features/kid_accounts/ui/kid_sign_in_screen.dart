import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/household_route.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/copy/kid_copy.dart';
import '../../../shared/time/household_clock.dart';
import '../../accounts/ui/account_menu_button.dart';
import '../model/kid_device.dart';
import '../model/kid_sign_in_entry.dart';
import '../state/kid_sign_in_controller.dart';
import 'kid_pairing_sheet.dart';
import 'kid_sign_in_card.dart';

/// Where a parent lets a child sign in on their own device, sees which devices
/// they are signed in on, and signs any of them out (accounts ADR-0003).
/// Reached from the household screen, by admins — the rules let nobody else
/// read the devices.
class KidSignInScreen extends StatelessWidget {
  const KidSignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<KidSignInController>();
    final failure = controller.actionFailure;
    return NestScaffold(
      title: KidCopy.manageTitle,
      leading: context.canPop()
          ? NestIconButton(
              icon: LucideIcons.arrowLeft,
              label: AppCopy.back,
              variant: NestIconButtonVariant.plain,
              onPressed: context.pop,
            )
          : null,
      trailing: const [AccountMenuButton()],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The sheet shows its own refusals while it is open; this banner is
          // for what the screen itself did — signing a device out.
          if (failure != null && !controller.isPairing)
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
            child: NestAsyncView<List<KidSignInEntry>>(
              state: controller.entries,
              isEmpty: (entries) => entries.isEmpty,
              onRetry: controller.retry,
              emptyBuilder: (_) => NestEmptyView(
                title: KidCopy.manageEmptyTitle,
                message: KidCopy.manageEmptyBody,
                icon: LucideIcons.baby,
                actionLabel: KidCopy.manageGoToHousehold,
                onAction: () => context.go(
                  HouseholdRoute.householdPathFor(controller.householdId),
                ),
              ),
              dataBuilder: (context, entries) =>
                  _Entries(entries: entries, controller: controller),
            ),
          ),
        ],
      ),
    );
  }
}

class _Entries extends StatelessWidget {
  const _Entries({required this.entries, required this.controller});

  final List<KidSignInEntry> entries;
  final KidSignInController controller;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final clock = context.read<HouseholdClock>();
    return ListView(
      padding: const EdgeInsets.only(bottom: NestSpace.huge),
      children: [
        Text(KidCopy.manageIntro, style: nest.text.bodySecondary),
        const SizedBox(height: NestSpace.lg),
        for (final entry in entries)
          Padding(
            padding: const EdgeInsets.only(bottom: NestSpace.lg),
            child: KidSignInCard(
              key: ValueKey(entry.member.id),
              entry: entry,
              clock: clock,
              onAddDevice: () => showKidPairingSheet(
                context: context,
                controller: controller,
                member: entry.member,
              ),
              onRevoke: (device) => _revoke(context, device),
              onSignOutEverywhere: () => _signOutEverywhere(context, entry),
            ),
          ),
      ],
    );
  }

  Future<void> _revoke(BuildContext context, KidDevice device) async {
    final confirmed = await showNestConfirm(
      context: context,
      title: KidCopy.manageRevokeConfirm,
      message: device.label.isEmpty
          ? KidCopy.manageUnnamedDevice
          : device.label,
      confirmLabel: KidCopy.manageRevoke,
      cancelLabel: KidCopy.manageCancel,
      isDangerous: true,
    );
    if (confirmed != true) return;
    await controller.revoke(device);
  }

  Future<void> _signOutEverywhere(
    BuildContext context,
    KidSignInEntry entry,
  ) async {
    final confirmed = await showNestConfirm(
      context: context,
      title: KidCopy.manageSignOutEverywhereConfirm,
      message: entry.member.displayName,
      confirmLabel: KidCopy.manageSignOutEverywhere,
      cancelLabel: KidCopy.manageCancel,
      isDangerous: true,
    );
    if (confirmed != true) return;
    await controller.signOutEverywhere(entry.member.id);
  }
}
