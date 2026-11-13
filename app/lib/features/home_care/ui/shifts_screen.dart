import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/flags/feature_flag.dart';
import '../../../shared/time/household_clock.dart';
import '../../../shared/ui/back_leading.dart';
import '../../avatars/ui/member_avatar.dart';
import '../../household/model/household_view.dart';
import '../../household/model/member.dart';
import '../model/shift/helper_shift.dart';
import '../state/helper_shifts_controller.dart';
import '../state/home_care_controller.dart';
import 'end_shift_sheet.dart';
import 'shift_clock.dart';
import 'switched_off_view.dart';

/// Who is clocked in, and every shift so far (home-care ADR-0007): a helper
/// sees her own, family everybody's — and can end one somebody forgot.
class ShiftsScreen extends StatelessWidget {
  const ShiftsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<HelperShiftsController>();
    final canManage = context.watch<HomeCareController>().access.canManage;
    final failure = controller.actionFailure;
    return NestScaffold(
      title: HomeCareShiftCopy.shifts,
      subtitle: HomeCareShiftCopy.subtitle,
      leading: backLeading(context),
      body: SwitchedOffView(
        flag: FeatureFlag.homeCareShifts,
        child: Column(
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
              child: NestAsyncView<List<HelperShift>>(
                state: controller.shifts,
                isEmpty: (shifts) => shifts.isEmpty,
                onRetry: controller.retry,
                emptyBuilder: (_) => NestEmptyView(
                  title: HomeCareShiftCopy.emptyTitle,
                  message: canManage
                      ? HomeCareShiftCopy.emptyBody
                      : HomeCareShiftCopy.emptyHelperBody,
                  icon: LucideIcons.clock,
                ),
                dataBuilder: (context, shifts) =>
                    _ShiftList(shifts: shifts, controller: controller),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShiftList extends StatelessWidget {
  const _ShiftList({required this.shifts, required this.controller});

  final List<HelperShift> shifts;
  final HelperShiftsController controller;

  @override
  Widget build(BuildContext context) {
    final members = {
      for (final member in context.watch<HouseholdView>().members)
        member.id: member,
    };
    final open = [
      for (final shift in shifts)
        if (shift.isOpen) shift,
    ];
    final past = [
      for (final shift in shifts)
        if (!shift.isOpen) shift,
    ];
    return ListView(
      padding: const EdgeInsets.only(bottom: NestSpace.huge),
      children: [
        if (open.isNotEmpty) ...[
          const NestSectionHeader(title: HomeCareShiftCopy.onNow),
          for (final shift in open)
            _OpenShiftRow(
              key: ValueKey(shift.id),
              shift: shift,
              helper: members[shift.helperId],
              controller: controller,
            ),
          const SizedBox(height: NestSpace.lg),
        ],
        if (past.isNotEmpty) ...[
          const NestSectionHeader(title: HomeCareShiftCopy.past),
          for (final shift in past)
            _PastShiftRow(
              key: ValueKey(shift.id),
              shift: shift,
              helper: members[shift.helperId],
            ),
        ],
      ],
    );
  }
}

class _OpenShiftRow extends StatelessWidget {
  const _OpenShiftRow({
    required this.shift,
    required this.helper,
    required this.controller,
    super.key,
  });

  final HelperShift shift;
  final Member? helper;
  final HelperShiftsController controller;

  @override
  Widget build(BuildContext context) {
    final clock = context.read<HouseholdClock>();
    final name = helper?.displayName ?? HomeCareCopy.helperGone;
    return Padding(
      padding: const EdgeInsets.only(bottom: NestSpace.md),
      child: NestCard(
        variant: NestCardVariant.tinted,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            NestListRow(
              leading: _ShiftAvatar(helper),
              title: name,
              subtitle: HomeCareShiftCopy.since(
                clock.shiftTime(shift.startedAt),
              ),
              trailing: shift.startedVia == HelperShift.frame
                  ? const _FrameTag()
                  : null,
            ),
            if (controller.canEnd(shift)) ...[
              const SizedBox(height: NestSpace.sm),
              NestButton(
                label: HomeCareShiftCopy.endShift,
                icon: LucideIcons.logOut,
                variant: NestButtonVariant.outline,
                size: NestButtonSize.medium,
                isLoading: controller.isBusy,
                onPressed: controller.isBusy
                    ? null
                    : () => _end(context, clock, name),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _end(
    BuildContext context,
    HouseholdClock clock,
    String name,
  ) async {
    final isOwn = controller.ownOpenShift?.id == shift.id;
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

class _PastShiftRow extends StatelessWidget {
  const _PastShiftRow({required this.shift, required this.helper, super.key});

  final HelperShift shift;
  final Member? helper;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final clock = context.read<HouseholdClock>();
    final length = shift.length;
    return Padding(
      padding: const EdgeInsets.only(bottom: NestSpace.xs),
      child: NestListRow(
        leading: _ShiftAvatar(helper),
        title: helper?.displayName ?? HomeCareCopy.helperGone,
        subtitle: clock.shiftSpan(shift),
        trailing: length == null
            ? null
            : Text(HomeCareShiftCopy.length(length), style: nest.text.label),
        footer: _isAtFrame(shift) ? const _FrameTag() : null,
      ),
    );
  }

  static bool _isAtFrame(HelperShift shift) =>
      shift.startedVia == HelperShift.frame ||
      shift.endedVia == HelperShift.frame;
}

class _ShiftAvatar extends StatelessWidget {
  const _ShiftAvatar(this.helper);

  final Member? helper;

  @override
  Widget build(BuildContext context) => switch (helper) {
    final Member helper => MemberAvatar(
      member: helper,
      size: NestSize.avatarSmall,
    ),
    null => const Icon(LucideIcons.clock),
  };
}

class _FrameTag extends StatelessWidget {
  const _FrameTag();

  @override
  Widget build(BuildContext context) => const NestTag(
    label: HomeCareShiftCopy.atTheFrame,
    icon: LucideIcons.monitor,
  );
}
