import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/flags/feature_flag.dart';
import '../../../shared/flags/feature_flags_controller.dart';
import '../../../shared/time/household_clock.dart';
import '../../../shared/ui/back_leading.dart';
import '../../avatars/ui/member_avatar.dart';
import '../../household/model/household_view.dart';
import '../../household/model/member.dart';
import '../../subscriptions/model/premium_feature.dart';
import '../../subscriptions/state/household_entitlement.dart';
import '../../subscriptions/ui/premium_area.dart';
import '../data/helper_shift_repository.dart';
import '../model/home_care_access.dart';
import '../model/shift/helper_shift.dart';
import '../state/open_helper_shifts_controller.dart';
import 'end_shift_sheet.dart';
import 'shift_clock.dart';

/// Home care is Premium in full (subscriptions ADR-0008): [child] for a
/// household that has it, and [LockedHomeCareScreen] for one known not to.
/// Until the entitlement is known this is `PremiumArea`, unchanged.
class HomeCarePremiumArea extends StatelessWidget {
  const HomeCarePremiumArea({
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
        feature: PremiumFeature.homeCare,
        title: title,
        child: child,
      );
    }
    return LockedHomeCareScreen(title: title);
  }
}

/// The locked place, which still offers the one thing the rules keep free:
/// clocking out a shift left open when Premium ended.
class LockedHomeCareScreen extends StatelessWidget {
  const LockedHomeCareScreen({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    final access = HomeCareAccess.of(context.watch<HouseholdView>());
    final mayEnd =
        access.isVisible &&
        context.watch<FeatureFlagsController>().isOn(
          FeatureFlag.homeCareShifts,
        );
    return NestScaffold(
      title: title,
      leading: backLeading(context),
      body: mayEnd
          ? ChangeNotifierProvider(
              key: ValueKey(access),
              create: (context) => OpenHelperShiftsController(
                repository: context.read<HelperShiftRepository>(),
                householdId: context.read<HouseholdView>().household.id,
                access: access,
              ),
              child: const _LockedWithOpenShifts(),
            )
          : const PremiumLockedView(feature: PremiumFeature.homeCare),
    );
  }
}

class _LockedWithOpenShifts extends StatelessWidget {
  const _LockedWithOpenShifts();

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final controller = context.watch<OpenHelperShiftsController>();
    final shifts = controller.shifts;
    final failure = controller.actionFailure;
    const locked = PremiumLockedView(feature: PremiumFeature.homeCare);
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
          const NestSectionHeader(title: HomeCareShiftCopy.onNow),
          const SizedBox(height: NestSpace.xs),
          Text(
            HomeCareShiftCopy.lockedOpenBody,
            style: nest.text.caption.copyWith(color: nest.colors.inkSecondary),
          ),
          const SizedBox(height: NestSpace.sm),
          for (final shift in shifts)
            _OpenShiftCard(
              key: ValueKey(shift.id),
              shift: shift,
              helper: members[shift.helperId],
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
    required this.helper,
    required this.controller,
    super.key,
  });

  final HelperShift shift;
  final Member? helper;
  final OpenHelperShiftsController controller;

  @override
  Widget build(BuildContext context) {
    final clock = context.read<HouseholdClock>();
    final isOwn = controller.isOwn(shift);
    final name = helper?.displayName ?? HomeCareCopy.helperGone;
    final member = helper;
    return Padding(
      padding: const EdgeInsets.only(bottom: NestSpace.md),
      child: NestCard(
        variant: NestCardVariant.tinted,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            NestListRow(
              leading: member == null
                  ? const Icon(LucideIcons.clock)
                  : MemberAvatar(member: member, size: NestSize.avatarSmall),
              title: isOwn ? HomeCareShiftCopy.onShiftTitle : name,
              subtitle: HomeCareShiftCopy.since(
                clock.shiftTime(shift.startedAt),
              ),
            ),
            const SizedBox(height: NestSpace.sm),
            NestButton(
              label: HomeCareShiftCopy.endShift,
              icon: LucideIcons.logOut,
              variant: NestButtonVariant.outline,
              size: NestButtonSize.medium,
              isLoading: controller.isBusy,
              onPressed: controller.isBusy
                  ? null
                  : () => _end(context, clock, name, isOwn: isOwn),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _end(
    BuildContext context,
    HouseholdClock clock,
    String name, {
    required bool isOwn,
  }) async {
    final ends = await showEndHelperShiftSheet(
      context: context,
      title: isOwn
          ? HomeCareShiftCopy.endTitle
          : HomeCareShiftCopy.endForTitle(name),
      body: isOwn
          ? HomeCareShiftCopy.endBody(clock.shiftTime(shift.startedAt))
          : HomeCareShiftCopy.endForBody,
    );
    if (ends) await controller.end(shift);
  }
}
