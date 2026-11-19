import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/household_place_redirect.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/copy/app_copy.dart';
import '../../calendar_sync/state/connected_calendars_controller.dart';
import '../../household/model/household_view.dart';
import '../../household/state/invite_step_controller.dart';
import '../state/setup_flow_controller.dart';
import 'onboarding_header.dart';

/// The payoff (onboarding ADR-0001): the bar full, Twig cheering once, and
/// what the nest now holds, in words. *Open my week* is the one thing that
/// closes the setup step; the household then opens on its first place.
class SetupReadyPanel extends StatelessWidget {
  const SetupReadyPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final flow = context.read<SetupFlowController>();
    final invites = context.watch<InviteStepController>();
    final view = context.watch<HouseholdView>();
    final calendars = switch (context
        .watch<ConnectedCalendarsController>()
        .connections) {
      AsyncData(:final value) => value.length,
      _ => 0,
    };
    final failure = invites.actionFailure;

    return ListView(
      padding: const EdgeInsets.only(bottom: NestSpace.huge),
      children: [
        const OnboardingHeader(
          title: OnboardingCopy.readyTitle,
          twigPose: NestTwigPose.celebrate,
          twigLine: OnboardingCopy.twigReady,
          twigAction: NestTwigAction.cheer,
        ),
        const SizedBox(height: NestSpace.xl),
        NestRiseIn(
          index: 2,
          child: NestCard(
            padding: const EdgeInsets.symmetric(vertical: NestSpace.xs),
            child: Column(
              children: [
                NestListRow(
                  leading: const NestIconTile(
                    icon: LucideIcons.usersRound,
                    tint: NestTileTint.guava,
                  ),
                  title: OnboardingCopy.readyPeople(view.members.length - 1),
                ),
                NestListRow(
                  leading: const NestIconTile(
                    icon: LucideIcons.calendarHeart,
                    tint: NestTileTint.lilac,
                  ),
                  title: OnboardingCopy.readyCalendars(calendars),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: NestSpace.xl),
        if (failure != null) ...[
          NestBanner(
            message: AppCopy.failure(failure),
            tone: NestBannerTone.danger,
            actionLabel: AppCopy.back,
            onAction: invites.dismissActionFailure,
          ),
          const SizedBox(height: NestSpace.md),
        ],
        NestStepActions(
          nextLabel: OnboardingCopy.readyOpen,
          nextIcon: LucideIcons.arrowRight,
          isBusy: invites.isBusy,
          onNext: invites.isBusy ? null : () => unawaited(_open(context)),
          backLabel: AppCopy.back,
          onBack: invites.isBusy ? null : flow.back,
        ),
      ],
    );
  }

  static Future<void> _open(BuildContext context) async {
    final closed = await context.read<InviteStepController>().finish();
    if (!closed || !context.mounted) return;
    context.go(firstPlaceFor(context.read<HouseholdView>()));
  }
}
