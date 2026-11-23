import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_update_copy.dart';
import '../data/app_restarter.dart';
import '../data/patch_updates.dart';
import '../state/patch_update_controller.dart';

/// Sits above the router, so the card covers every screen, signed in or not
/// (foundation ADR-0026). The app under it is kept, hidden and unfocusable,
/// until the restart takes it down.
class PatchRestartHost extends StatefulWidget {
  const PatchRestartHost({required this.child, super.key});

  final Widget child;

  @override
  State<PatchRestartHost> createState() => _PatchRestartHostState();
}

class _PatchRestartHostState extends State<PatchRestartHost> {
  late final PatchUpdateController _controller = PatchUpdateController(
    updates: context.read<PatchUpdates>(),
    restarter: context.read<AppRestarter>(),
  );
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onShow: _opened);
    WidgetsBinding.instance.addPostFrameCallback((_) => _opened());
  }

  void _opened() {
    if (mounted) _controller.opened();
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      child: widget.child,
      builder: (context, app) {
        final ready = _controller.restartReady;
        return Stack(
          fit: StackFit.expand,
          children: [
            TickerMode(
              enabled: !ready,
              child: ExcludeFocus(
                excluding: ready,
                child: Offstage(offstage: ready, child: app),
              ),
            ),
            if (ready) _RestartCard(controller: _controller),
          ],
        );
      },
    );
  }
}

class _RestartCard extends StatelessWidget {
  const _RestartCard({required this.controller});

  final PatchUpdateController controller;

  static const _maxWidth = 480.0;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final relaunch = controller.canRelaunch;
    return Material(
      color: nest.colors.canvas,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(NestSpace.gutter),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _maxWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Center(
                    child: NestTwig(
                      pose: NestTwigPose.celebrate,
                      size: NestSize.twigLarge,
                      action: NestTwigAction.hop,
                    ),
                  ),
                  const SizedBox(height: NestSpace.xxl),
                  NestIntro(
                    title: AppUpdateCopy.title,
                    body: relaunch
                        ? AppUpdateCopy.relaunchBody
                        : AppUpdateCopy.closeBody,
                  ),
                  const SizedBox(height: NestSpace.xxxl),
                  NestButton(
                    label: relaunch
                        ? AppUpdateCopy.relaunch
                        : AppUpdateCopy.close,
                    icon: relaunch ? LucideIcons.refreshCw : LucideIcons.power,
                    isLoading: controller.restarting,
                    onPressed: controller.restart,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
