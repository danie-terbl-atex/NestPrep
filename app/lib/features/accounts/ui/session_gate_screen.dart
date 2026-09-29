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
          // The very first thing anybody sees on a cold start. Three grey bars
          // with no words is a screen that looks broken for as long as the
          // session read takes, which on a bad connection is a while.
          // It follows the native splash, so it opens on the same nest in the
          // same place and the hand-over reads as one screen (ADR-0003).
          _ => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const NestBrandMark(width: NestSize.brandMarkLarge),
              const SizedBox(height: NestSpace.xxl),
              Text(
                AppCopy.sessionStarting,
                style: NestTheme.of(context).text.bodySecondary,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: NestSpace.lg),
              // One pulsing bar the nest's width, not rows: nothing list-shaped
              // is coming to this screen, so row placeholders promised content
              // that never arrives. It still moves, so it still says "working".
              const NestSkeleton(
                width: NestSize.brandMarkMedium,
                height: NestSpace.sm,
                radius: NestRadius.pill,
              ),
            ],
          ),
        },
      ),
    );
  }
}
