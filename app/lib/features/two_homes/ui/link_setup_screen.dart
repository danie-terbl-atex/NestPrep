import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/two_homes_route.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/time/calendar_date.dart';
import '../../../shared/ui/back_leading.dart';
import '../model/co_parent_home.dart';
import '../model/custody_side.dart';
import '../state/link_setup_controller.dart';
import 'home_identity_fields.dart';
import 'invite_code_card.dart';
import 'privacy_boundary.dart';
import 'schedule_editor.dart';

/// Making a code for the other home (household ADR-0004), in the order a
/// parent thinks it: which child, what we call our home, the schedule we
/// propose, and what the other home will see — then the code.
class LinkSetupScreen extends StatelessWidget {
  const LinkSetupScreen({required this.today, super.key});

  final CalendarDate today;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LinkSetupController>();
    final failure = controller.actionFailure;
    final invite = controller.invite;
    final nest = NestTheme.of(context);
    final ours = CoParentHome(
      name: controller.homeName.trim().isEmpty
          ? TwoHomesSetupCopy.yourHome
          : controller.homeName.trim(),
      color: controller.color,
    );
    final theirs = CoParentHome(
      name: TwoHomesSetupCopy.theOtherHome,
      color: MemberColor.values.firstWhere((each) => each != controller.color),
    );
    CoParentHome homeOf(CustodySide side) =>
        side == CustodySide.a ? ours : theirs;

    return NestScaffold(
      title: TwoHomesSetupCopy.setupTitle,
      leading: backLeading(context),
      body: ListView(
        padding: const EdgeInsets.only(bottom: NestSpace.huge),
        children: [
          if (failure != null) ...[
            NestBanner(
              message: AppCopy.failure(failure),
              tone: NestBannerTone.danger,
              actionLabel: AppCopy.back,
              onAction: controller.dismissActionFailure,
            ),
            const SizedBox(height: NestSpace.lg),
          ],
          if (invite != null)
            NestRiseIn(
              child: InviteCodeCard(
                invite: invite,
                shareOutcome: controller.shareOutcome,
                onShare: controller.share,
                onDone: () => _leave(context, controller.householdId),
              ),
            )
          else if (controller.kids.isEmpty)
            const NestEmptyView(
              icon: LucideIcons.baby,
              title: TwoHomesSetupCopy.noKidsTitle,
              message: TwoHomesSetupCopy.noKidsBody,
            )
          else ...[
            const NestSectionHeader(title: TwoHomesSetupCopy.whichChild),
            const SizedBox(height: NestSpace.sm),
            Wrap(
              spacing: NestSpace.sm,
              runSpacing: NestSpace.sm,
              children: [
                for (final kid in controller.kids)
                  NestChip(
                    label: kid.displayName,
                    isSelected: controller.childId == kid.id,
                    onTap: () => controller.chooseChild(kid.id),
                  ),
              ],
            ),
            const SizedBox(height: NestSpace.xl),
            const NestSectionHeader(title: TwoHomesSetupCopy.yourHome),
            const SizedBox(height: NestSpace.sm),
            HomeIdentityFields(
              name: controller.homeName,
              color: controller.color,
              onName: controller.nameHome,
              onColor: controller.chooseColor,
            ),
            const SizedBox(height: NestSpace.xl),
            const NestSectionHeader(title: TwoHomesSetupCopy.scheduleTitle),
            Text(
              TwoHomesSetupCopy.scheduleBody,
              style: nest.text.caption.copyWith(color: nest.colors.inkTertiary),
            ),
            const SizedBox(height: NestSpace.md),
            ChangeNotifierProvider.value(
              value: controller.draft,
              child: ScheduleEditor(homeOf: homeOf, today: today),
            ),
            const SizedBox(height: NestSpace.xl),
            const NestSectionHeader(title: TwoHomesSetupCopy.privacyTitle),
            const SizedBox(height: NestSpace.sm),
            const PrivacyBoundary(),
            const SizedBox(height: NestSpace.xl),
            NestButton(
              label: TwoHomesSetupCopy.makeCode,
              icon: LucideIcons.keyRound,
              isLoading: controller.isCreating,
              onPressed: controller.canCreate ? controller.create : null,
            ),
          ],
        ],
      ),
    );
  }
}

/// Back where the person came from — or, from a deep link with nothing under
/// it, to the two-homes list (`FE-17`).
void _leave(BuildContext context, String householdId) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(TwoHomesRoute.pathFor(householdId));
  }
}
