import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../features/household/model/household_view.dart';
import '../features/nanny_hub/data/photo_update_repository.dart';
import '../features/nanny_hub/data/shift_repository.dart';
import '../features/nanny_hub/state/photo_feed_controller.dart';
import '../features/nanny_hub/state/photo_library.dart';
import '../features/nanny_hub/ui/photo_feed_screen.dart';
import 'household_route.dart';
import 'nanny_hub_route.dart';

/// One shift's photo updates (nanny-hub ADR-0004), for whatever is below it:
/// shift mode, where the carer sends them, and the parents' feed.
Widget withPhotoFeed(GoRouterState state, {required Widget child}) =>
    ChangeNotifierProvider(
      create: (context) {
        final view = context.read<HouseholdView>();
        return PhotoFeedController(
          photoUpdateRepository: context.read<PhotoUpdateRepository>(),
          shiftRepository: context.read<ShiftRepository>(),
          photos: context.read<PhotoLibrary>(),
          householdId: HouseholdRoute.idFrom(state),
          shiftId: NannyHubRoute.parameterFrom(
            state,
            NannyHubRoute.shiftParameter,
          ),
          memberId: view.viewerMember?.id ?? '',
          isFamily: view.permissions.isFamily,
        );
      },
      child: child,
    );

/// The parents' live feed of one shift's photos.
GoRoute photoFeedRoute() => GoRoute(
  path: NannyHubRoute.photosPath,
  builder: (context, state) =>
      withPhotoFeed(state, child: const PhotoFeedScreen()),
);
