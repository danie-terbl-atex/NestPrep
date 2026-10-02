import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../features/add_to_checkers/data/checkers_directory.dart';
import '../features/add_to_checkers/state/checkers_link_controller.dart';
import '../features/add_to_checkers/ui/checkers_link_screen.dart';
import 'checkers_link_route.dart';

/// Linking a Checkers account (the Checkers build contract), in its own file
/// so the route table gains one line.
GoRoute checkersLinkRoute() => GoRoute(
  path: CheckersLinkRoute.path,
  builder: (context, state) => ChangeNotifierProvider(
    create: (context) =>
        CheckersLinkController(directory: context.read<CheckersDirectory>()),
    child: CheckersLinkScreen(
      returnWhenLinked:
          state.uri.queryParameters[CheckersLinkRoute.returnParameter] == '1',
    ),
  ),
);
