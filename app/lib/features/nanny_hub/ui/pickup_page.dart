import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/ui/back_leading.dart';
import '../model/nanny_hub_view.dart';
import '../model/nanny_pickups.dart';
import '../state/nanny_hub_controller.dart';
import '../state/pickup_controller.dart';

/// Everything a pickup screen renders once both halves have loaded: the hub
/// (children, members, the parents' numbers) and the pickups themselves.
typedef PickupView = ({NannyHubView hub, NannyPickups pickups});

/// The frame both pickup screens share: the title, the way back, a banner for
/// a refused change from either controller, and one set of four states over
/// both reads (`FE-08`) — so the door check never shows people before it
/// knows who the children are.
class PickupPage extends StatelessWidget {
  const PickupPage({
    required this.title,
    required this.builder,
    this.isEmpty,
    this.emptyBuilder,
    this.trailing = const [],
    super.key,
  });

  final String title;
  final Widget Function(BuildContext context, PickupView view) builder;

  /// When the subject — a child — is gone.
  final bool Function(PickupView view)? isEmpty;
  final WidgetBuilder? emptyBuilder;
  final List<Widget> trailing;

  static AsyncState<PickupView> _both(
    AsyncState<NannyHubView> hub,
    AsyncState<NannyPickups> pickups,
  ) => switch ((hub, pickups)) {
    (AsyncFailure(:final failure), _) => AsyncFailure(failure),
    (_, AsyncFailure(:final failure)) => AsyncFailure(failure),
    (AsyncData(value: final hub), AsyncData(value: final pickups)) => AsyncData(
      (hub: hub, pickups: pickups),
    ),
    _ => const AsyncLoading(),
  };

  @override
  Widget build(BuildContext context) {
    final hub = context.watch<NannyHubController>();
    final pickups = context.watch<PickupController>();
    final failure = pickups.actionFailure ?? hub.actionFailure;
    return NestScaffold(
      title: title,
      leading: backLeading(context),
      trailing: trailing,
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
                  pickups.dismissActionFailure();
                  hub.dismissActionFailure();
                },
              ),
            ),
          Expanded(
            child: NestAsyncView<PickupView>(
              state: _both(hub.view, pickups.pickups),
              isEmpty: isEmpty ?? (_) => false,
              onRetry: () {
                pickups.retry();
                hub.retry();
              },
              emptyBuilder: emptyBuilder ?? (_) => const SizedBox.shrink(),
              dataBuilder: builder,
            ),
          ),
        ],
      ),
    );
  }
}
