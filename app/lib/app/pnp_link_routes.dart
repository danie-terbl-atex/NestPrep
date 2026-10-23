import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../features/add_to_pnp/data/pnp_directory.dart';
import '../features/add_to_pnp/state/pnp_link_controller.dart';
import '../features/add_to_pnp/ui/pnp_link_screen.dart';
import '../features/add_to_pnp/ui/pnp_login_web_view.dart';
import 'pnp_link_route.dart';

/// Linking a Pick n Pay account (add-to-pnp ADR-0003), in its own file so
/// the route table gains one line.
GoRoute pnpLinkRoute() => GoRoute(
  path: PnpLinkRoute.path,
  builder: (context, state) => ChangeNotifierProvider(
    create: (context) =>
        PnpLinkController(directory: context.read<PnpDirectory>()),
    child: PnpLinkScreen(
      signInPage: PnpLoginWebView.build,
      returnWhenLinked:
          state.uri.queryParameters[PnpLinkRoute.returnParameter] == '1',
    ),
  ),
);
