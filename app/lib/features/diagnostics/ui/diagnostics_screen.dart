import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../design/gallery/design_gallery_screen.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../state/ping_list_controller.dart';
import 'ping_list_view.dart';

/// The placeholder home route: proves the build reaches Firestore. Renders all
/// four async states (`FE-08`) from the controller it finds above it.
class DiagnosticsScreen extends StatelessWidget {
  const DiagnosticsScreen({super.key});

  static const path = '/';

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PingListController>();
    final sendFailure = controller.sendFailure;
    return NestScaffold(
      title: AppCopy.diagnosticsTitle,
      subtitle: AppCopy.diagnosticsSubtitle,
      trailing: [
        NestIconButton(
          icon: Icons.palette_outlined,
          label: AppCopy.galleryTitle,
          onPressed: () => context.push(DesignGalleryScreen.path),
        ),
      ],
      floatingAction: Padding(
        padding: const EdgeInsets.only(bottom: NestSpace.lg),
        child: NestButton(
          label: AppCopy.diagnosticsSendPing,
          icon: Icons.send_outlined,
          isExpanded: false,
          isLoading: controller.isSending,
          onPressed: controller.sendPing,
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (sendFailure != null)
            Padding(
              padding: const EdgeInsets.only(bottom: NestSpace.lg),
              child: NestBanner(
                message: AppCopy.failure(sendFailure),
                tone: NestBannerTone.danger,
                actionLabel: AppCopy.retry,
                onAction: controller.sendPing,
              ),
            ),
          Expanded(
            child: NestAsyncView(
              state: controller.pings,
              isEmpty: (pings) => pings.isEmpty,
              onRetry: controller.retry,
              emptyBuilder: (_) => NestEmptyView(
                title: AppCopy.diagnosticsEmptyTitle,
                message: AppCopy.diagnosticsEmptyBody,
                icon: Icons.cloud_outlined,
                actionLabel: AppCopy.diagnosticsSendPing,
                onAction: controller.sendPing,
              ),
              dataBuilder: (_, pings) => PingListView(pings: pings),
            ),
          ),
        ],
      ),
    );
  }
}
