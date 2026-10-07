import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../design/nest_kit.dart';
import '../features/accounts/state/session_controller.dart';
import '../features/household/state/pending_invite.dart';
import '../shared/copy/app_copy.dart';
import 'app_providers.dart';
import 'app_router.dart';
import 'firebase_bootstrap.dart';
import 'notification_host.dart';

class NestPrepApp extends StatelessWidget {
  const NestPrepApp({required this.services, super.key});

  final FirebaseServices services;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: appProviders(services),
      child: const _NestPrepRouterHost(),
    );
  }
}

/// Holds the one `GoRouter` for the life of the app. It is built here rather
/// than in `NestPrepApp` because it needs the `SessionController` the providers
/// above create, and rebuilding a router loses the navigation stack.
class _NestPrepRouterHost extends StatefulWidget {
  const _NestPrepRouterHost();

  @override
  State<_NestPrepRouterHost> createState() => _NestPrepRouterHostState();
}

class _NestPrepRouterHostState extends State<_NestPrepRouterHost> {
  late final GoRouter _router = createAppRouter(
    context.read<SessionController>(),
    context.read<PendingInvite>(),
  );

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppCopy.appName,
      theme: nestThemeData(NestTheme.light()),
      darkTheme: nestThemeData(NestTheme.dark()),
      routerConfig: _router,
      // Where a push meets the running app (notifications ADR-0001).
      builder: (context, child) =>
          NotificationHost(router: _router, child: child ?? const SizedBox()),
    );
  }
}
