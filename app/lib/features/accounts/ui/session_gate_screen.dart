import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/copy/app_copy.dart';
import '../state/session_controller.dart';

/// What the app shows while it works out who is using it, and when that read
/// fails (`FE-08`). Every other route is redirected here until the session is
/// known, so this is the only screen that can be reached signed out or in.
class SessionGateScreen extends StatelessWidget {
  const SessionGateScreen({super.key});

  static const path = '/';

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SessionController>();
    return NestScaffold(
      body: Center(
        child: switch (controller.session) {
          AsyncFailure(:final failure) => NestErrorView(
            message: AppCopy.failure(failure),
            retryLabel: AppCopy.retry,
            onRetry: controller.retry,
          ),
          _ => const NestLoadingView(rows: 3),
        },
      ),
    );
  }
}
