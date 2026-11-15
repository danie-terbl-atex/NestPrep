import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/time/household_clock.dart';
import '../../../shared/ui/back_leading.dart';
import '../../avatars/ui/member_avatar.dart';
import '../../household/model/household_view.dart';
import '../../household/model/member.dart';
import '../../subscriptions/model/premium_feature.dart';
import '../../subscriptions/state/household_entitlement.dart';
import '../../subscriptions/ui/premium_area.dart';
import '../data/shift_directory.dart';
import '../data/shift_repository.dart';
import '../model/nanny_access.dart';
import '../model/shift.dart';
import '../state/open_shifts_controller.dart';
import 'hub_clock.dart';

/// The hub is Premium in full (subscriptions ADR-0008): [child] for a
/// household that has it, and [LockedNannyHubScreen] for one known not to.
/// Until the entitlement is known this is `PremiumArea`, unchanged.
class NannyHubPremiumArea extends StatelessWidget {
  const NannyHubPremiumArea({
    required this.title,
    required this.child,
    super.key,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final entitlement = context.watch<HouseholdEntitlement>();
    if (entitlement.isPremium || !entitlement.isKnown) {
      return PremiumArea(
        feature: PremiumFeature.nannyHub,
        title: title,
        child: child,
      );
    }
    return LockedNannyHubScreen(title: title);
  }
}

/// The locked place, which still offers the one thing the server keeps free:
/// ending a shift left open when Premium ended.
class LockedNannyHubScreen extends StatelessWidget {
  const LockedNannyHubScreen({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    final access = NannyAccess.of(context.watch<HouseholdView>());
    return NestScaffold(
      title: title,
      leading: backLeading(context),
      body: OpenShiftsController.listensFor(access)
          ? ChangeNotifierProvider(
              key: ValueKey(access),
              create: (context) => OpenShiftsController(
                shiftRepository: context.read<ShiftRepository>(),
                shiftDirectory: context.read<ShiftDirectory>(),
                householdId: context.read<HouseholdView>().household.id,
                access: access,
              ),
              child: const _LockedWithOpenShifts(),
            )
          : const PremiumLockedView(feature: PremiumFeature.nannyHub),
    );
  }
}

class _LockedWithOpenShifts extends StatelessWidget {
  const _LockedWithOpenShifts();

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final controller = context.watch<OpenShiftsController>();
    final shifts = controller.shifts;
    final failure = controller.actionFailure;
    const locked = PremiumLockedView(feature: PremiumFeature.nannyHub);
    if (shifts.isEmpty && failure == null) return locked;
    final members = {
      for (final member in context.watch<HouseholdView>().members)
        member.id: member,
    };
    return ListView(
      padding: const EdgeInsets.only(bottom: NestSpace.huge),
      children: [
        if (failure != null)
          Padding(
            padding: const EdgeInsets.only(bottom: NestSpace.md),
            child: NestBanner(
              message: AppCopy.failure(failure),
              tone: NestBannerTone.danger,
              actionLabel: AppCopy.back,
              onAction: controller.dismissActionFailure,
            ),
          ),
        locked,
        if (shifts.isNotEmpty) ...[
          const NestSectionHeader(title: NannyShiftCopy.lockedOpenShifts),
          const SizedBox(height: NestSpace.xs),
          Text(
            NannyShiftCopy.lockedOpenBody,
            style: nest.text.caption.copyWith(color: nest.colors.inkSecondary),
          ),
          const SizedBox(height: NestSpace.sm),
          for (final shift in shifts)
            _OpenShiftCard(
              key: ValueKey(shift.id),
              shift: shift,
              carer: members[shift.carerMemberId],
              controller: controller,
            ),
        ],
      ],
    );
  }
}

class _OpenShiftCard extends StatelessWidget {
  const _OpenShiftCard({
    required this.shift,
    required this.carer,
    required this.controller,
    super.key,
  });

  final Shift shift;
  final Member? carer;
  final OpenShiftsController controller;

  @override
  Widget build(BuildContext context) {
    final clock = context.read<HouseholdClock>();
    final isOwn = controller.isOwn(shift);
    final member = carer;
    final name = member?.displayName ?? '';
    final startedAt = shift.startedAt;
    return Padding(
      padding: const EdgeInsets.only(bottom: NestSpace.md),
      child: NestCard(
        variant: NestCardVariant.tinted,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            NestListRow(
              leading: member == null
                  ? const Icon(LucideIcons.baby)
                  : MemberAvatar(member: member, size: NestSize.avatarSmall),
              title: isOwn || member == null ? NannyCopy.onShiftTitle : name,
              subtitle: NannyShiftCopy.shiftStarted(
                startedAt == null
                    ? NannyShiftCopy.summaryPending
                    : clock.timeOf(startedAt),
              ),
            ),
            const SizedBox(height: NestSpace.sm),
            NestButton(
              label: NannyShiftCopy.endShift,
              icon: LucideIcons.moonStar,
              variant: NestButtonVariant.outline,
              size: NestButtonSize.medium,
              isLoading: controller.isEnding,
              onPressed: controller.isEnding
                  ? null
                  : () => _end(context, isOwn || member == null ? null : name),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _end(BuildContext context, String? otherName) async {
    final ends = await showNestSheet<bool>(
      context: context,
      title: otherName == null
          ? NannyShiftCopy.endShiftTitle
          : NannyShiftCopy.lockedEndForTitle(otherName),
      builder: (context) => SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              NannyShiftCopy.lockedEndBody,
              style: NestTheme.of(context).text.bodySecondary,
            ),
            const SizedBox(height: NestSpace.xxl),
            NestButton(
              label: NannyShiftCopy.endShift,
              icon: LucideIcons.moonStar,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: NestSpace.sm),
            NestButton(
              label: NannyCopy.cancel,
              variant: NestButtonVariant.ghost,
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );
    if (ends ?? false) await controller.end(shift);
  }
}
