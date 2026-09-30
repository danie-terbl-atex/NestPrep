import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/copy/app_copy.dart';
import '../state/session_controller.dart';

/// What the app shows while it works out who is using it, and when that read
/// fails or stalls (`FE-08`). Every other route is redirected here until the
/// session is known, so this is the only screen that can be reached signed out
/// or in — which is why it is never a spinner with no way out: a start still
/// loading after [stallAfter] shows *Try again* and *Sign out* (accounts
/// ADR-0008).
class SessionGateScreen extends StatefulWidget {
  const SessionGateScreen({super.key});

  static const path = '/';

  /// Past the session check's own bound, so an offline start has already
  /// fallen back to the cache by then; what is left is a backend answering
  /// nothing, and waiting longer will not change that.
  static const stallAfter = Duration(seconds: 18);

  @override
  State<SessionGateScreen> createState() => _SessionGateScreenState();
}

class _SessionGateScreenState extends State<SessionGateScreen> {
  Timer? _stallTimer;
  bool _stalled = false;

  @override
  void initState() {
    super.initState();
    _watchForStall();
  }

  @override
  void dispose() {
    _stallTimer?.cancel();
    super.dispose();
  }

  void _watchForStall() {
    _stallTimer?.cancel();
    _stalled = false;
    _stallTimer = Timer(SessionGateScreen.stallAfter, () {
      if (mounted) setState(() => _stalled = true);
    });
  }

  Future<void> _retry(SessionController controller) async {
    setState(_watchForStall);
    await controller.retry();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SessionController>();
    // Retrying cannot fix every failure here, and this screen is the only one
    // reachable, so it always offers the other way out too.
    Widget failed(String message) => NestErrorView(
      message: message,
      retryLabel: AppCopy.retry,
      onRetry: () => _retry(controller),
      secondaryLabel: AppCopy.signOut,
      onSecondary: controller.signOut,
    );
    return NestScaffold(
      body: Center(
        child: switch (controller.session) {
          AsyncFailure(:final failure) => failed(AppCopy.failure(failure)),
          AsyncLoading() when _stalled => failed(AppCopy.sessionStalled),
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
