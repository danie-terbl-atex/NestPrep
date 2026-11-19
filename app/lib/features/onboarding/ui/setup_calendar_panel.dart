import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/copy/calendar_sync_copy.dart';
import '../../calendar_sync/model/calendar_connection.dart';
import '../../calendar_sync/state/connected_calendars_controller.dart';
import '../../calendar_sync/ui/calendar_connect_list.dart';
import '../../calendar_sync/ui/calendar_connections_section.dart';
import '../state/setup_flow_controller.dart';
import 'onboarding_header.dart';

/// Step five of five: bring the calendar the family already uses (onboarding
/// ADR-0001, calendar ADR-0003), read-only, so its plans are there on the
/// first day. Only what this phone and deployment can connect is offered; a
/// calendar link always can be. Twig thinks while the browser is open and
/// cheers when a connection lands.
class SetupCalendarPanel extends StatelessWidget {
  const SetupCalendarPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final flow = context.read<SetupFlowController>();
    final calendars = context.watch<ConnectedCalendarsController>();
    final nest = NestTheme.of(context);
    final connections = switch (calendars.connections) {
      AsyncData(:final value) => value,
      _ => const <CalendarConnection>[],
    };
    final isWaiting = calendars.isAwaitingBrowser;
    final newest = connections.lastOrNull;

    return ListView(
      padding: const EdgeInsets.only(bottom: NestSpace.huge),
      children: [
        OnboardingHeader(
          title: OnboardingCopy.calendarTitle,
          body: OnboardingCopy.calendarBody,
          twigPose: switch ((isWaiting, newest)) {
            (true, _) => NestTwigPose.thinking,
            (false, null) => NestTwigPose.planning,
            (false, _) => NestTwigPose.celebrate,
          },
          twigLine: switch ((isWaiting, newest)) {
            (true, _) => OnboardingCopy.twigCalendarWaiting,
            (false, null) => OnboardingCopy.twigCalendar,
            (false, final connection?) => OnboardingCopy.twigCalendarIn(
              connection.provider,
            ),
          },
          twigAction: newest == null
              ? NestTwigAction.arrive
              : NestTwigAction.cheer,
          twigActionKey: connections.length,
        ),
        const SizedBox(height: NestSpace.xl),
        const CalendarConnectBanners(),
        const NestRiseIn(
          index: 2,
          child: CalendarConnectList(onlyAvailable: true),
        ),
        const SizedBox(height: NestSpace.sm),
        Text(
          CalendarSyncCopy.privacyNote,
          style: nest.text.caption.copyWith(color: nest.colors.inkTertiary),
        ),
        if (connections.isNotEmpty) ...[
          const SizedBox(height: NestSpace.xxl),
          const NestSectionHeader(title: OnboardingCopy.calendarConnected),
          const SizedBox(height: NestSpace.sm),
          CalendarConnectionsSection(
            onDisconnect: (connection) =>
                confirmDisconnect(context, calendars, connection),
            onChooseCalendars: () => chooseAppleCalendars(context, calendars),
          ),
        ],
        const SizedBox(height: NestSpace.xl),
        NestStepActions(
          nextLabel: connections.isEmpty
              ? OnboardingCopy.skip
              : OnboardingCopy.calendarNext,
          nextIcon: LucideIcons.arrowRight,
          onNext: calendars.isConnecting ? null : flow.next,
          backLabel: AppCopy.back,
          onBack: flow.back,
        ),
      ],
    );
  }
}
