import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/ui/back_leading.dart';
import '../model/nanny_hub_view.dart';
import '../model/shift_log.dart';
import '../state/nanny_hub_controller.dart';
import '../state/shift_controller.dart';
import 'nanny_hub_screen.dart';
import 'shift_body.dart';

/// Shift mode: calm, big and one-handed. What happened is one tap on a large
/// button; the checklist for this part of the evening is right under it; the
/// log reads newest first; the emergency sheet is in the header; ending the
/// shift is at the very bottom, out of reach of a stray thumb (nanny-hub
/// ADR-0002).
class ShiftScreen extends StatelessWidget {
  const ShiftScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final shift = context.watch<ShiftController>();
    final hub = context.watch<NannyHubController>();
    final failure = shift.actionFailure ?? hub.actionFailure;
    return NestScaffold(
      title: NannyCopy.shiftTitle,
      leading: backLeading(context),
      trailing: const [EmergencyLinkButton()],
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
                onAction: () {
                  shift.dismissActionFailure();
                  hub.dismissActionFailure();
                },
              ),
            ),
          Expanded(
            child: NestAsyncView<(ShiftLog, NannyHubView)>(
              state: _both(shift.log, hub.view),
              isEmpty: (both) => both.$1.isGone,
              onRetry: () {
                shift.retry();
                hub.retry();
              },
              emptyBuilder: (_) => const NestEmptyView(
                title: NannyCopy.shiftGoneTitle,
                message: NannyCopy.shiftGoneBody,
                icon: Icons.event_busy_outlined,
              ),
              dataBuilder: (context, both) => ShiftBody(
                log: both.$1,
                view: both.$2,
                shift: shift,
                hub: hub,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Shift mode needs the shift's log and the hub's children and checklists:
  /// one loading state for both, and the first failure of either.
  static AsyncState<(ShiftLog, NannyHubView)> _both(
    AsyncState<ShiftLog> log,
    AsyncState<NannyHubView> view,
  ) => switch ((log, view)) {
    (AsyncFailure(:final failure), _) => AsyncFailure(failure),
    (_, AsyncFailure(:final failure)) => AsyncFailure(failure),
    (AsyncData(value: final shift), AsyncData(value: final hub)) => AsyncData((
      shift,
      hub,
    )),
    _ => const AsyncLoading(),
  };
}
