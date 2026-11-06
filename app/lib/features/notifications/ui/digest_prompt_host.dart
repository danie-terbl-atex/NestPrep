import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/notifications_route.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/time/household_clock.dart';
import '../data/digest_prompt_store.dart';
import '../data/notification_repository.dart';
import '../model/inbox_item.dart';
import '../state/digest_prompt_controller.dart';
import 'digest_prompt_banner.dart';

/// Floats today's digest over the household on the first open of the day
/// (notifications ADR-0005). An open is the first frame, or the app coming
/// back from the background — `onShow`, not `onResume`, which a permission
/// dialog or the biometric sheet also fires.
class DigestPromptHost extends StatefulWidget {
  const DigestPromptHost({
    required this.householdId,
    required this.memberId,
    required this.location,
    required this.child,
    super.key,
  });

  final String householdId;
  final String memberId;
  final String location;
  final Widget child;

  static const _maxWidth = 560.0;

  @override
  State<DigestPromptHost> createState() => _DigestPromptHostState();
}

class _DigestPromptHostState extends State<DigestPromptHost> {
  late DigestPromptController _controller = _controllerFor(widget);
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onShow: _opened);
    WidgetsBinding.instance.addPostFrameCallback((_) => _opened());
  }

  @override
  void didUpdateWidget(DigestPromptHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.householdId == widget.householdId &&
        oldWidget.memberId == widget.memberId) {
      return;
    }
    _controller.dispose();
    _controller = _controllerFor(widget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _opened());
  }

  DigestPromptController _controllerFor(DigestPromptHost host) =>
      DigestPromptController(
        repository: context.read<NotificationRepository>(),
        store: context.read<DigestPromptStore>(),
        clock: context.read<HouseholdClock>(),
        householdId: host.householdId,
        memberId: host.memberId,
      );

  void _opened() {
    if (mounted) unawaited(_controller.opened());
  }

  void _open(InboxItem digest) {
    _controller.dismiss();
    final digestPath = NotificationsRoute.itemPathFor(
      widget.householdId,
      digest.id,
    );
    unawaited(context.push<void>(digestPath));
  }

  bool get _isOnNotifications => widget.location.startsWith(
    NotificationsRoute.pathFor(widget.householdId),
  );

  @override
  void dispose() {
    _lifecycle.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final motion = NestMotion.of(context);
    return Stack(
      children: [
        widget.child,
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            minimum: const EdgeInsets.only(top: NestSpace.sm),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: NestSpace.gutter),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: DigestPromptHost._maxWidth,
                  ),
                  child: ListenableBuilder(
                    listenable: _controller,
                    builder: (context, _) {
                      final digest = _isOnNotifications
                          ? null
                          : _controller.digest;
                      return AnimatedSwitcher(
                        duration: motion.slow,
                        switchInCurve: NestMotion.emphasized,
                        switchOutCurve: NestMotion.exit,
                        transitionBuilder: (child, animation) =>
                            SlideTransition(
                              position: Tween(
                                begin: const Offset(0, -0.6),
                                end: Offset.zero,
                              ).animate(animation),
                              child: FadeTransition(
                                opacity: animation,
                                child: child,
                              ),
                            ),
                        child: digest == null
                            ? const SizedBox.shrink()
                            : DigestPromptBanner(
                                key: ValueKey(digest.id),
                                digest: digest,
                                onOpen: () => _open(digest),
                                onDismiss: _controller.dismiss,
                              ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
