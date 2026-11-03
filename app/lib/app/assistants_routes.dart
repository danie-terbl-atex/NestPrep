import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../features/accounts/state/session_controller.dart';
import '../features/assistants/data/assistant_repository.dart';
import '../features/assistants/state/connected_assistants_controller.dart';
import '../features/assistants/ui/connected_assistants_screen.dart';
import '../features/household/model/household_view.dart';
import '../shared/time/household_clock.dart';
import 'assistants_route.dart';
import 'household_route.dart';
import 'viewer_member.dart';

/// *Connected assistants*' route under the household shell (assistants
/// ADR-0001), in its own file so the route table gains one line.
GoRoute assistantsRoute(SessionController session) => GoRoute(
  path: AssistantsRoute.path,
  builder: (context, state) => ChangeNotifierProvider(
    create: (context) => ConnectedAssistantsController(
      assistantRepository: context.read<AssistantRepository>(),
      householdClock: context.read<HouseholdClock>(),
      householdId: HouseholdRoute.idFrom(state),
      viewerUid: session.uidOrEmpty,
      viewerMemberId: viewerMemberIdOf(context),
      isFamily: context.read<HouseholdView>().permissions.isFamily,
    ),
    child: const ConnectedAssistantsScreen(),
  ),
);
