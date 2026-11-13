import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../features/accounts/model/kid_identity.dart';
import '../features/accounts/model/session.dart';
import '../features/accounts/state/session_controller.dart';
import '../features/accounts/ui/session_gate_screen.dart';
import '../features/avatars/data/avatar_photo_store.dart';
import '../features/avatars/data/avatar_repository.dart';
import '../features/avatars/model/avatar_place.dart';
import '../features/avatars/state/avatar_creation_controller.dart';
import '../features/avatars/state/avatar_keepsakes_controller.dart';
import '../features/avatars/state/avatar_studio_controller.dart';
import '../features/avatars/ui/avatar_studio_closed.dart';
import '../features/avatars/ui/avatar_studio_screen.dart';
import '../features/avatars/ui/avatar_studio_tab.dart';
import '../features/avatars/ui/seen_stage_marker.dart';
import '../features/chore_points/data/points_repository.dart';
import '../features/household/data/household_repository.dart';
import '../features/household/model/household_view.dart';
import '../shared/async/async_state.dart';
import '../shared/flags/feature_flag.dart';
import '../shared/flags/feature_flags_controller.dart';
import '../shared/time/household_clock.dart';
import 'household_route.dart';

abstract final class AvatarRoute {
  static const segment =
      '${HouseholdRoute.householdSegment}/avatar/:${HouseholdRoute.memberParameter}';
  static const path = '${HouseholdRoute.path}/$segment';
  static const kidPath = '/kid/avatar';
  static const tabParameter = 'tab';

  static String pathFor(
    String householdId,
    String memberId, {
    AvatarStudioTab? tab,
  }) => _withTab(
    '${HouseholdRoute.householdPathFor(householdId)}/avatar/$memberId',
    tab,
  );

  static String kidPathFor({AvatarStudioTab? tab}) => _withTab(kidPath, tab);

  static String _withTab(String path, AvatarStudioTab? tab) =>
      tab == null ? path : '$path?$tabParameter=${tab.name}';

  static bool isOn(FeatureFlagsController? flags) =>
      flags?.isOn(FeatureFlag.avatars) ?? false;

  static bool creationsOn(FeatureFlagsController? flags) =>
      isOn(flags) && (flags?.isOn(FeatureFlag.avatarCreations) ?? false);

  static bool canOpen(HouseholdView view, String memberId) =>
      view.permissions.isFamily || view.viewerMember?.id == memberId;

  static AvatarStudioTab tabFrom(GoRouterState state) =>
      AvatarStudioTab.fromName(state.uri.queryParameters[tabParameter]);
}

GoRoute avatarStudioRoute() => GoRoute(
  path: AvatarRoute.path,
  builder: (context, state) {
    final memberId = HouseholdRoute.memberIdFrom(state);
    final view = context.read<HouseholdView>();
    if (!AvatarRoute.isOn(context.read<FeatureFlagsController?>()) ||
        !AvatarRoute.canOpen(view, memberId)) {
      return const AvatarStudioClosed();
    }
    final householdId = HouseholdRoute.idFrom(state);
    final viewerMemberId = view.viewerMember?.id ?? '';
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => AvatarStudioController(
            householdRepository: context.read<HouseholdRepository>(),
            avatarRepository: context.read<AvatarRepository>(),
            pointsRepository: context.read<PointsRepository>(),
            photoStore: context.read<AvatarPhotoStore>(),
            householdId: householdId,
            memberId: memberId,
            viewerMemberId: viewerMemberId,
            viewerUid: view.viewerUid,
          ),
        ),
        ..._creationProviders(
          context,
          householdId: householdId,
          memberId: memberId,
          viewerMemberId: viewerMemberId,
          viewerUid: view.viewerUid,
        ),
      ],
      child: AvatarStudioScreen(initialTab: AvatarRoute.tabFrom(state)),
    );
  },
);

GoRoute kidAvatarStudioRoute(SessionController session) => GoRoute(
  path: AvatarRoute.kidPath,
  builder: (context, state) {
    final (kid, uid) = switch (session.session) {
      AsyncData(value: KidSignedIn(:final kid, :final uid)) => (kid, uid),
      _ => (null, ''),
    };
    if (kid == null) return const SessionGateScreen();
    if (!AvatarRoute.isOn(context.read<FeatureFlagsController?>())) {
      return const AvatarStudioClosed();
    }
    return MultiProvider(
      providers: [
        StreamProvider<AvatarPlace?>(
          initialData: null,
          create: (context) => _placeOf(context, kid),
        ),
        ChangeNotifierProvider(
          create: (context) => AvatarStudioController(
            householdRepository: context.read<HouseholdRepository>(),
            avatarRepository: context.read<AvatarRepository>(),
            pointsRepository: context.read<PointsRepository>(),
            photoStore: context.read<AvatarPhotoStore>(),
            householdId: kid.householdId,
            memberId: kid.memberId,
            viewerMemberId: kid.memberId,
            viewerUid: uid,
          ),
        ),
        ..._creationProviders(
          context,
          householdId: kid.householdId,
          memberId: kid.memberId,
          viewerMemberId: kid.memberId,
          viewerUid: uid,
        ),
      ],
      child: SeenStageMarker(
        child: AvatarStudioScreen(initialTab: AvatarRoute.tabFrom(state)),
      ),
    );
  },
);

List<SingleChildWidget> _creationProviders(
  BuildContext context, {
  required String householdId,
  required String memberId,
  required String viewerMemberId,
  required String viewerUid,
}) => [
  if (AvatarRoute.creationsOn(context.read<FeatureFlagsController?>()))
    ChangeNotifierProvider(
      create: (context) => AvatarCreationController(
        avatarRepository: context.read<AvatarRepository>(),
        photoStore: context.read<AvatarPhotoStore>(),
        householdId: householdId,
        memberId: memberId,
        viewerMemberId: viewerMemberId,
        viewerUid: viewerUid,
      ),
    ),
  ChangeNotifierProvider(
    create: (context) => AvatarKeepsakesController(
      avatarRepository: context.read<AvatarRepository>(),
      householdId: householdId,
      memberId: memberId,
      viewerMemberId: viewerMemberId,
    ),
  ),
];

Stream<AvatarPlace?> _placeOf(BuildContext context, KidIdentity kid) => context
    .read<HouseholdRepository>()
    .watchHousehold(kid.householdId)
    .map(
      (household) => household == null
          ? null
          : AvatarPlace.of(
              householdId: household.id,
              timeZone: household.timeZone,
              today: HouseholdClock(household.timeZone).today,
            ),
    )
    .handleError((Object _) {});
