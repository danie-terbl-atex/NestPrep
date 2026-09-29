import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../features/accounts/state/session_controller.dart';
import '../features/home_care/data/cleaning_job_repository.dart';
import '../features/home_care/data/home_care_library_repository.dart';
import '../features/home_care/data/job_photo_store.dart';
import '../features/home_care/state/home_care_controller.dart';
import '../features/home_care/state/job_actions.dart';
import '../features/home_care/state/job_composer_controller.dart';
import '../features/home_care/state/job_controller.dart';
import '../features/home_care/state/photo_intake.dart';
import '../features/home_care/ui/home_care_screen.dart';
import '../features/home_care/ui/job_compose_screen.dart';
import '../features/home_care/ui/job_screen.dart';
import '../features/home_care/ui/products_screen.dart';
import '../features/home_care/ui/review_screen.dart';
import '../features/home_care/ui/rooms_screen.dart';
import '../features/home_care/ui/step_through_screen.dart';
import '../features/household/model/household_view.dart';
import '../shared/time/household_clock.dart';
import 'home_care_route.dart';
import 'household_route.dart';
import 'viewer_member.dart';

/// Home care's routes under the household shell (home-care ADR-0001), in
/// their own file so the route table gains one line.
///
/// Every screen shares one controller and one set of listeners, which follows
/// the household view — a changed grant can move which jobs the viewer may
/// ask for (household ADR-0003). One job's three screens share a second
/// controller of their own, for its history and its photos.
ShellRoute homeCareRoutes(SessionController session) => ShellRoute(
  builder: (context, state, child) =>
      ChangeNotifierProxyProvider<HouseholdView, HomeCareController>(
        create: (context) => HomeCareController(
          jobRepository: context.read<CleaningJobRepository>(),
          libraryRepository: context.read<HomeCareLibraryRepository>(),
          householdId: HouseholdRoute.idFrom(state),
          household: context.read<HouseholdView>(),
        ),
        update: (context, view, controller) =>
            controller!..followHousehold(view),
        child: child,
      ),
  routes: [
    GoRoute(
      path: HomeCareRoute.path,
      builder: (context, state) =>
          HomeCareScreen(pile: HomeCareRoute.pileFrom(state)),
    ),
    GoRoute(
      path: HomeCareRoute.newJobPath,
      builder: (context, state) => ChangeNotifierProvider(
        create: (context) => JobComposerController(
          jobRepository: context.read<CleaningJobRepository>(),
          photoStore: context.read<JobPhotoStore>(),
          photoIntake: context.read<PhotoIntake>(),
          householdId: HouseholdRoute.idFrom(state),
          memberId: viewerMemberIdOf(context),
          viewerUid: session.uidOrEmpty,
          today: context.read<HouseholdClock>().today,
        ),
        child: const JobComposeScreen(),
      ),
    ),
    GoRoute(
      path: HomeCareRoute.roomsPath,
      builder: (context, state) => const RoomsScreen(),
    ),
    GoRoute(
      path: HomeCareRoute.productsPath,
      builder: (context, state) => const ProductsScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) =>
          _jobScope(context, state, session, child),
      routes: [
        GoRoute(
          path: HomeCareRoute.jobPath,
          builder: (context, state) => const JobScreen(),
        ),
        GoRoute(
          path: HomeCareRoute.stepsPath,
          builder: (context, state) => const StepThroughScreen(),
        ),
        GoRoute(
          path: HomeCareRoute.reviewPath,
          builder: (context, state) => const ReviewScreen(),
        ),
      ],
    ),
  ],
);

/// One job's controller, keyed by the job so moving straight from one job to
/// another never shows the first one's photos.
Widget _jobScope(
  BuildContext context,
  GoRouterState state,
  SessionController session,
  Widget child,
) {
  final jobId = HomeCareRoute.jobIdFrom(state);
  return ChangeNotifierProxyProvider<HomeCareController, JobController>(
    key: ValueKey(jobId),
    create: (context) => JobController(
      jobRepository: context.read<CleaningJobRepository>(),
      photoStore: context.read<JobPhotoStore>(),
      householdId: HouseholdRoute.idFrom(state),
      jobId: jobId,
      actions: (controller) => JobActions(
        controller: controller,
        jobRepository: context.read<CleaningJobRepository>(),
        photoStore: context.read<JobPhotoStore>(),
        photoIntake: context.read<PhotoIntake>(),
        memberId: viewerMemberIdOf(context),
        viewerUid: session.uidOrEmpty,
      ),
    ),
    update: (context, home, controller) => controller!..followBoard(home.board),
    child: child,
  );
}
