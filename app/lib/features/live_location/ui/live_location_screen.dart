import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/copy/app_copy.dart';
import '../../accounts/ui/account_menu_button.dart';
import '../model/live_location_view.dart';
import '../state/live_location_controller.dart';
import 'located_member_row.dart';
import 'share_location_card.dart';

/// Where everybody in the household is, for as long as each of them said so.
///
/// It is reached from the household screen rather than the bottom bar: the bar
/// belongs to the four things a household does every day, and this is not one
/// of them. All four async states come from the kit (`FE-08`).
class LiveLocationScreen extends StatelessWidget {
  const LiveLocationScreen({super.key});

  static const routeName = 'live-location';

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LiveLocationController>();
    final failure = controller.actionFailure;
    return NestScaffold(
      title: AppCopy.locationTitle,
      leading: context.canPop()
          ? NestIconButton(
              icon: Icons.arrow_back,
              label: AppCopy.back,
              variant: NestIconButtonVariant.plain,
              onPressed: context.pop,
            )
          : null,
      trailing: const [AccountMenuButton()],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
          // The person's own control sits above the list and outside its async
          // states, so a household with nobody sharing still has the way to
          // start (`FE-08`).
          if (controller.view case AsyncData(value: final view)) ...[
            ShareLocationCard(
              viewer: view.viewer,
              onShareFor: controller.shareFor,
              onStop: controller.stopSharing,
            ),
            const SizedBox(height: NestSpace.lg),
          ],
          Expanded(
            child: NestAsyncView<LiveLocationView>(
              state: controller.view,
              isEmpty: (view) => view.isEmpty,
              onRetry: controller.retry,
              emptyBuilder: (_) => const NestEmptyView(
                title: AppCopy.locationAloneTitle,
                message: AppCopy.locationAloneBody,
                icon: Icons.person_pin_circle_outlined,
              ),
              dataBuilder: (_, view) => _WhereEverybodyIs(view: view),
            ),
          ),
        ],
      ),
    );
  }
}

class _WhereEverybodyIs extends StatelessWidget {
  const _WhereEverybodyIs({required this.view});

  final LiveLocationView view;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: NestSpace.huge),
      children: [
        for (final located in view.others)
          Padding(
            padding: const EdgeInsets.only(bottom: NestSpace.sm),
            child: LocatedMemberRow(
              key: ValueKey(located.member.id),
              located: located,
            ),
          ),
      ],
    );
  }
}
