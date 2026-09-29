import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/copy/kid_copy.dart';
import '../../../shared/failure/app_failure.dart';
import '../../accounts/state/session_controller.dart';
import '../model/kid_day.dart';
import '../state/kid_home_controller.dart';
import 'kid_day_view.dart';

/// The only screen a kid device has (accounts ADR-0003). Loading, error and
/// success come from the kit; the one failure that is not an error — a parent
/// signed this device out — gets its own calm screen and a way back to the
/// start, never a retry button that can never work.
class KidHomeScreen extends StatelessWidget {
  const KidHomeScreen({super.key});

  static const path = '/kid';

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<KidHomeController>();
    final session = context.read<SessionController>();
    final failure = controller.actionFailure;
    final day = controller.day;
    if (day case AsyncFailure(
      failure: KidSignInFailure(problem: KidSignInProblem.deviceDisconnected),
    )) {
      return NestScaffold(
        body: NestEmptyView(
          title: KidCopy.disconnectedTitle,
          message: KidCopy.problem(KidSignInProblem.deviceDisconnected),
          icon: Icons.phonelink_erase_rounded,
          actionLabel: KidCopy.disconnectedAction,
          onAction: session.signOut,
        ),
      );
    }
    return NestScaffold(
      title: KidCopy.homeTitle,
      trailing: [
        NestIconButton(
          icon: Icons.logout_rounded,
          label: KidCopy.signOut,
          variant: NestIconButtonVariant.plain,
          onPressed: () => _signOut(context, session),
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (failure != null)
            Padding(
              padding: const EdgeInsets.only(bottom: NestSpace.lg),
              child: NestBanner(
                message: AppCopy.failure(failure),
                tone: NestBannerTone.danger,
                actionLabel: AppCopy.back,
                onAction: controller.dismissActionFailure,
              ),
            ),
          Expanded(
            child: NestAsyncView<KidDay>(
              state: day,
              // A day always has something on it — the food, at least — so
              // the view carries its own "no jobs" rather than being replaced.
              isEmpty: (_) => false,
              onRetry: controller.retry,
              emptyBuilder: (_) => const SizedBox.shrink(),
              dataBuilder: (context, value) => KidDayView(
                day: value,
                onToggle: (index) => controller.toggle(value.chores[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Signing out means a grown-up has to make a new code, so it asks first —
  /// and "stay" is the easy answer.
  static Future<void> _signOut(
    BuildContext context,
    SessionController session,
  ) async {
    final confirmed = await showNestConfirm(
      context: context,
      title: KidCopy.signOutConfirm,
      message: KidCopy.signOutBody,
      confirmLabel: KidCopy.signOut,
      cancelLabel: KidCopy.signOutCancel,
      isDangerous: true,
    );
    if (confirmed != true) return;
    await session.signOut();
  }
}
