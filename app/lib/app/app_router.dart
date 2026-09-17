import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../design/gallery/design_gallery_screen.dart';
import '../features/diagnostics/data/ping_repository.dart';
import '../features/diagnostics/state/ping_list_controller.dart';
import '../features/diagnostics/ui/diagnostics_screen.dart';

/// Every screen is reachable by path (`FE-17`). A route creates the controller
/// its screen reads, so the controller's lifetime is the screen's.
final appRouter = GoRouter(
  routes: [
    GoRoute(
      path: DiagnosticsScreen.path,
      builder: (context, state) => ChangeNotifierProvider(
        create: (context) => PingListController(
          context.read<PingRepository>(),
          sentFrom: defaultTargetPlatform.name,
        ),
        child: const DiagnosticsScreen(),
      ),
    ),
    if (kDebugMode)
      GoRoute(
        path: DesignGalleryScreen.path,
        builder: (context, state) => const DesignGalleryScreen(),
      ),
  ],
);
