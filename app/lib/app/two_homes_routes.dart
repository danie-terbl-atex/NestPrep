import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../features/household/data/invite_sharer.dart';
import '../features/household/model/household_view.dart';
import '../features/household/model/member.dart';
import '../features/household/model/member_role.dart';
import '../features/two_homes/data/two_homes_directory.dart';
import '../features/two_homes/data/two_homes_repository.dart';
import '../features/two_homes/model/two_homes_access.dart';
import '../features/two_homes/state/handover_controller.dart';
import '../features/two_homes/state/join_link_controller.dart';
import '../features/two_homes/state/link_controller.dart';
import '../features/two_homes/state/link_setup_controller.dart';
import '../features/two_homes/state/schedule_draft.dart';
import '../features/two_homes/state/two_homes_controller.dart';
import '../features/two_homes/ui/handover_screen.dart';
import '../features/two_homes/ui/join_link_screen.dart';
import '../features/two_homes/ui/link_screen.dart';
import '../features/two_homes/ui/link_setup_screen.dart';
import '../features/two_homes/ui/privacy_screen.dart';
import '../features/two_homes/ui/schedule_request_screen.dart';
import '../features/two_homes/ui/two_homes_screen.dart';
import '../shared/flags/feature_flag.dart';
import '../shared/flags/feature_flags_controller.dart';
import '../shared/time/household_clock.dart';
import 'household_route.dart';
import 'two_homes_route.dart';

/// Two homes' routes under the household shell (household ADR-0004), in their
/// own file so the route table gains one line. Each screen creates its own
/// controller, so its listeners live exactly as long as it does.
///
/// With the `coParenting` flag off every path goes back to the household
/// screen, so an old link or a stale deep link lands somewhere real.
List<GoRoute> twoHomesRoutes() => [
  GoRoute(
    path: TwoHomesRoute.path,
    redirect: _whenOff,
    builder: (context, state) => ChangeNotifierProvider(
      create: (context) => TwoHomesController(
        twoHomesRepository: context.read<TwoHomesRepository>(),
        twoHomesDirectory: context.read<TwoHomesDirectory>(),
        householdId: HouseholdRoute.idFrom(state),
        today: context.read<HouseholdClock>().today,
      ),
      child: const TwoHomesScreen(),
    ),
  ),
  GoRoute(
    path: TwoHomesRoute.setupPath,
    redirect: _whenOff,
    builder: (context, state) {
      final today = context.read<HouseholdClock>().today;
      return ChangeNotifierProvider(
        create: (context) => LinkSetupController(
          twoHomesDirectory: context.read<TwoHomesDirectory>(),
          inviteSharer: context.read<InviteSharer>(),
          householdId: HouseholdRoute.idFrom(state),
          kids: _kidsOf(context),
          draft: ScheduleDraft(today: today),
        ),
        child: LinkSetupScreen(today: today),
      );
    },
  ),
  GoRoute(
    path: TwoHomesRoute.joinPath,
    redirect: _whenOff,
    builder: (context, state) => ChangeNotifierProvider(
      create: (context) => JoinLinkController(
        twoHomesDirectory: context.read<TwoHomesDirectory>(),
        householdId: HouseholdRoute.idFrom(state),
        kids: _kidsOf(context),
      ),
      child: const JoinLinkScreen(),
    ),
  ),
  GoRoute(
    path: TwoHomesRoute.privacyPath,
    redirect: _whenOff,
    builder: (context, state) => const PrivacyScreen(),
  ),
  GoRoute(
    path: TwoHomesRoute.linkPath,
    redirect: _whenOff,
    builder: (context, state) => ChangeNotifierProvider(
      create: (context) => _linkController(context, state),
      child: const LinkScreen(),
    ),
  ),
  GoRoute(
    path: TwoHomesRoute.schedulePath,
    redirect: _whenOff,
    builder: (context, state) => ChangeNotifierProvider(
      create: (context) => _linkController(context, state),
      child: const ScheduleRequestScreen(),
    ),
  ),
  GoRoute(
    path: TwoHomesRoute.handoverPath,
    redirect: _whenOff,
    builder: (context, state) => ChangeNotifierProvider(
      create: (context) => HandoverController(
        twoHomesRepository: context.read<TwoHomesRepository>(),
        twoHomesDirectory: context.read<TwoHomesDirectory>(),
        householdId: HouseholdRoute.idFrom(state),
        linkId: TwoHomesRoute.linkIdFrom(state),
        date: TwoHomesRoute.dateFrom(state),
      ),
      child: HandoverScreen(today: context.read<HouseholdClock>().today),
    ),
  ),
];

String? _whenOff(BuildContext context, GoRouterState state) {
  return context.read<FeatureFlagsController>().isOn(FeatureFlag.coParenting)
      ? null
      : HouseholdRoute.householdPathFor(HouseholdRoute.idFrom(state));
}

LinkController _linkController(BuildContext context, GoRouterState state) {
  final view = context.read<HouseholdView>();
  return LinkController(
    twoHomesRepository: context.read<TwoHomesRepository>(),
    twoHomesDirectory: context.read<TwoHomesDirectory>(),
    householdId: HouseholdRoute.idFrom(state),
    linkId: TwoHomesRoute.linkIdFrom(state),
    today: context.read<HouseholdClock>().today,
    access: TwoHomesAccess.of(view),
  );
}

/// The household's kid profiles: the only ones a link can be for.
List<Member> _kidsOf(BuildContext context) => [
  for (final member in context.read<HouseholdView>().members)
    if (member.role == MemberRole.kid) member,
];
