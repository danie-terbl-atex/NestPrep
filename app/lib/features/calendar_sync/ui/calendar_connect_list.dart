import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/copy/calendar_sync_copy.dart';
import '../../../shared/failure/app_failure.dart';
import '../model/calendar_connection.dart';
import '../model/calendar_provider.dart';
import '../state/connected_calendars_controller.dart';
import 'apple_calendar_picker_sheet.dart';
import 'calendar_link_sheet.dart';
import 'provider_connect_row.dart';

/// The ways this phone can bring a calendar in (calendar ADR-0003), one row
/// each, shared by the connected-calendars screen and the setup flow's
/// calendar step (onboarding ADR-0001), so there is one OAuth, Apple and link
/// path. Reads the [ConnectedCalendarsController] above it.
///
/// [onlyAvailable] leaves out a provider this deployment has not set up,
/// where a first-run step would otherwise say "not set up yet"; the screen
/// keeps it, in words.
class CalendarConnectList extends StatelessWidget {
  const CalendarConnectList({this.onlyAvailable = false, super.key});

  final bool onlyAvailable;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ConnectedCalendarsController>();
    return NestCard(
      padding: const EdgeInsets.symmetric(vertical: NestSpace.xs),
      child: Column(
        children: [
          for (final provider in controller.providersToConnect)
            if (!onlyAvailable || controller.isAvailable(provider))
              ProviderConnectRow(
                key: ValueKey(provider),
                provider: provider,
                isAvailable: controller.isAvailable(provider),
                isBusy: controller.isConnecting,
                onConnect: () => connectCalendar(context, controller, provider),
              ),
        ],
      ),
    );
  }
}

/// What the connect rows need said above them: a refusal (with the way to
/// Settings when Apple Calendar was refused), Apple access lost, or where to
/// finish while the browser is open.
class CalendarConnectBanners extends StatelessWidget {
  const CalendarConnectBanners({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ConnectedCalendarsController>();
    final failure = controller.actionFailure;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (failure != null)
          Padding(
            padding: const EdgeInsets.only(bottom: NestSpace.md),
            child: NestBanner(
              message: AppCopy.failure(failure),
              tone: NestBannerTone.danger,
              actionLabel: _needsSettings(failure)
                  ? CalendarSyncCopy.openSettings
                  : AppCopy.back,
              onAction: _needsSettings(failure)
                  ? () {
                      controller.dismissActionFailure();
                      unawaited(controller.openAppleSettings());
                    }
                  : controller.dismissActionFailure,
            ),
          )
        else if (controller.appleAccessLost)
          Padding(
            padding: const EdgeInsets.only(bottom: NestSpace.md),
            child: NestBanner(
              message: CalendarSyncCopy.appleAccessLost,
              tone: NestBannerTone.warning,
              actionLabel: CalendarSyncCopy.openSettings,
              onAction: controller.openAppleSettings,
            ),
          ),
        if (controller.isAwaitingBrowser)
          const Padding(
            padding: EdgeInsets.only(bottom: NestSpace.md),
            child: NestBanner(message: CalendarSyncCopy.browserOpened),
          ),
      ],
    );
  }

  static bool _needsSettings(AppFailure failure) =>
      failure is CalendarSyncFailure &&
      failure.problem == CalendarSyncProblem.appleCalendarDenied;
}

/// Google and Outlook open their consent page; Apple Calendar asks for the
/// phone's calendars; anything else is a pasted link.
Future<void> connectCalendar(
  BuildContext context,
  ConnectedCalendarsController controller,
  CalendarProvider provider,
) async {
  if (provider.usesOAuth) return controller.connect(provider);
  if (provider.readsFromPhone) {
    return chooseAppleCalendars(context, controller);
  }
  final link = await showCalendarLinkSheet(context);
  if (link == null) return;
  await controller.connectLink(link);
}

Future<void> chooseAppleCalendars(
  BuildContext context,
  ConnectedCalendarsController controller,
) async {
  final calendars = await controller.appleCalendars();
  if (calendars == null || !context.mounted) return;
  final chosen = await showAppleCalendarPicker(
    context,
    calendars: calendars,
    chosen: controller.appleCalendarIds,
  );
  if (chosen == null) return;
  await controller.linkApple(chosen);
}

Future<void> confirmDisconnect(
  BuildContext context,
  ConnectedCalendarsController controller,
  CalendarConnection connection,
) async {
  final confirmed = await showNestConfirm(
    context: context,
    title: CalendarSyncCopy.disconnectConfirm,
    message: CalendarSyncCopy.disconnectBody,
    confirmLabel: CalendarSyncCopy.disconnect,
    cancelLabel: AppCopy.householdCancel,
    isDangerous: true,
  );
  if (confirmed != true) return;
  await controller.disconnect(connection);
}
