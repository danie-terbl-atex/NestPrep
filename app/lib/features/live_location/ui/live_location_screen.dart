import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/household_route.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../accounts/ui/account_menu_button.dart';
import '../../household/model/household_area.dart';
import '../../household/model/household_view.dart';
import '../../subscriptions/model/premium_feature.dart';
import '../../subscriptions/ui/premium_gate.dart';
import '../data/location_engine.dart';
import '../model/live_location_view.dart';
import '../model/located_member.dart';
import '../state/always_sharing.dart';
import '../state/live_location_controller.dart';
import 'always_sharing_flow.dart';
import 'family_map.dart';
import 'located_member_row.dart';
import 'maps_enabled.dart';
import 'share_location_card.dart';

/// Where everybody in the household is (live-location ADR-0003 to ADR-0007):
/// a map when the build has a Maps key, the list otherwise.
class LiveLocationScreen extends StatelessWidget {
  const LiveLocationScreen({this.showMap = mapsEnabled, super.key});

  static const routeName = 'live-location';

  final bool showMap;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LiveLocationController>();
    final failure = controller.actionFailure;
    final stoppedBecause = context.watch<AlwaysSharing?>()?.stoppedBecause;
    final banners = [
      if (failure != null)
        NestBanner(
          message: AppCopy.failure(failure),
          tone: NestBannerTone.danger,
          actionLabel: AppCopy.back,
          onAction: controller.dismissActionFailure,
        ),
      if (stoppedBecause != null)
        NestBanner(
          message: _stopped(stoppedBecause),
          tone: NestBannerTone.warning,
          actionLabel: AppCopy.back,
          onAction: context.read<AlwaysSharing>().dismissStopReason,
        ),
    ];
    return NestScaffold(
      title: LocationCopy.title,
      leading: context.canPop()
          ? NestIconButton(
              icon: LucideIcons.arrowLeft,
              label: AppCopy.back,
              variant: NestIconButtonVariant.plain,
              onPressed: context.pop,
            )
          : null,
      trailing: [
        NestIconButton(
          icon: LucideIcons.mapPinned,
          label: LocationCopy.places,
          variant: NestIconButtonVariant.plain,
          onPressed: () => context.push(
            HouseholdRoute.placesPathFor(controller.householdId),
          ),
        ),
        const AccountMenuButton(),
      ],
      bodyPadding: showMap
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: NestSpace.gutter),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final banner in banners)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                NestSpace.gutter,
                0,
                NestSpace.gutter,
                NestSpace.md,
              ),
              child: banner,
            ),
          Expanded(
            child: NestAsyncView<LiveLocationView>(
              state: controller.view,
              isEmpty: (_) => false,
              onRetry: controller.retry,
              emptyBuilder: (_) => const SizedBox.shrink(),
              dataBuilder: (context, view) =>
                  showMap ? _OnTheMap(view: view) : _Everybody(view: view),
            ),
          ),
        ],
      ),
    );
  }

  static String _stopped(EngineStopReason reason) => switch (reason) {
    EngineStopReason.refused => LocationCopy.stoppedRefused,
    EngineStopReason.permissionRevoked => LocationCopy.stoppedPermission,
    EngineStopReason.signedOut ||
    EngineStopReason.paused => LocationCopy.stoppedSignedOut,
  };
}

class _OnTheMap extends StatelessWidget {
  const _OnTheMap({required this.view});

  final LiveLocationView view;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Stack(
      children: [
        Positioned.fill(
          child: FamilyMap(
            members: view.onTheMap,
            places: view.places,
            onMemberTap: (located) => openHistory(context, located),
          ),
        ),
        DraggableScrollableSheet(
          initialChildSize: 0.38,
          minChildSize: 0.18,
          maxChildSize: 0.9,
          builder: (context, scroll) => DecoratedBox(
            decoration: BoxDecoration(
              color: nest.colors.canvas,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(NestRadius.xxl),
              ),
              boxShadow: nest.shadows.floating,
            ),
            child: _Everybody(view: view, scroll: scroll),
          ),
        ),
      ],
    );
  }
}

class _Everybody extends StatelessWidget {
  const _Everybody({required this.view, this.scroll});

  final LiveLocationView view;
  final ScrollController? scroll;

  @override
  Widget build(BuildContext context) {
    final controller = context.read<LiveLocationController>();
    final always = context.watch<AlwaysSharing?>();
    final memberId = controller.viewerMemberId;
    final sharingAlways =
        always?.isSharingFor(controller.householdId, memberId) ?? false;
    return ListView(
      controller: scroll,
      padding: EdgeInsets.fromLTRB(
        scroll == null ? 0 : NestSpace.gutter,
        scroll == null ? 0 : NestSpace.lg,
        scroll == null ? 0 : NestSpace.gutter,
        NestSpace.huge,
      ),
      children: [
        ShareLocationCard(
          viewer: view.viewer,
          onShareFor: controller.shareFor,
          onStop: controller.stopSharing,
          sharingAlways: sharingAlways,
          alwaysBusy: always?.busy ?? false,
          onAlways: always == null
              ? null
              : () => controller.perform(
                  () => startAlwaysSharing(
                    context,
                    memberId: memberId,
                    places: controller.places,
                  ),
                ),
          onPause: always == null
              ? null
              : () => controller.perform(
                  () => always.stop(
                    householdId: controller.householdId,
                    memberId: memberId,
                  ),
                ),
          onBatteryHelp: always == null
              ? null
              : () => controller.perform(always.openBatterySettings),
        ),
        const SizedBox(height: NestSpace.lg),
        if (view.isEmpty)
          const NestEmptyView(
            title: LocationCopy.aloneTitle,
            message: LocationCopy.aloneBody,
            icon: LucideIcons.mapPin,
          ),
        for (final located in [?view.viewer, ...view.others])
          if (located.member.id != memberId || located.isSomewhere)
            Padding(
              padding: const EdgeInsets.only(bottom: NestSpace.sm),
              child: LocatedMemberRow(
                key: ValueKey(located.member.id),
                located: located,
                onTap: () => openHistory(context, located),
              ),
            ),
      ],
    );
  }
}

/// History is premium; the paywall opens on it rather than an empty day.
Future<void> openHistory(BuildContext context, LocatedMember located) async {
  final view = context.read<HouseholdView>();
  if (!view.permissions.canView(HouseholdArea.location)) return;
  if (!await ensurePremium(context, feature: PremiumFeature.familyLocation)) {
    return;
  }
  if (!context.mounted) return;
  await context.push(
    HouseholdRoute.historyPathFor(view.household.id, located.member.id),
  );
}
