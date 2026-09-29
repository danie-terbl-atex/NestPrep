import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/ui/back_leading.dart';
import '../model/nanny_hub_view.dart';
import '../state/nanny_hub_controller.dart';

/// The frame every hub screen shares: its title, the way back, the banner for
/// a refused action, and the hub's four states from the kit (`FE-08`). A
/// screen supplies what it shows once the hub has loaded — and, for a screen
/// whose subject can vanish (a child removed while their card is open), what
/// it says when it has.
class NannyHubPage extends StatelessWidget {
  const NannyHubPage({
    required this.title,
    required this.builder,
    this.isEmpty,
    this.emptyBuilder,
    this.trailing = const [],
    this.floatingAction,
    super.key,
  });

  final String title;
  final Widget Function(BuildContext context, NannyHubView view) builder;

  /// When the subject is gone. The hub itself is never "empty": its screens
  /// say what to add in place, beside the control that adds it (`FE-08`).
  final bool Function(NannyHubView view)? isEmpty;
  final WidgetBuilder? emptyBuilder;
  final List<Widget> trailing;
  final Widget? floatingAction;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<NannyHubController>();
    final failure = controller.actionFailure;
    return NestScaffold(
      title: title,
      leading: backLeading(context),
      trailing: trailing,
      floatingAction: floatingAction,
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
            child: NestAsyncView<NannyHubView>(
              state: controller.view,
              isEmpty: isEmpty ?? (_) => false,
              onRetry: controller.retry,
              emptyBuilder: emptyBuilder ?? (_) => const SizedBox.shrink(),
              dataBuilder: builder,
            ),
          ),
        ],
      ),
    );
  }
}
