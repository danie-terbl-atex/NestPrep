import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../design/nest_kit.dart';
import '../features/accounts/state/session_controller.dart';
import '../features/notifications/data/notification_repository.dart';
import '../features/notifications/data/push_gateway.dart';
import '../features/notifications/model/push_arrival.dart';
import '../features/notifications/state/push_registrar.dart';
import '../shared/copy/notifications_copy.dart';
import 'push_tap_router.dart';

/// Where a push meets the running app (notifications ADR-0001): it starts
/// this phone's registration once the first frame is up — asking nobody
/// anything — shows a push that arrives while the app is open as the app's own
/// banner, and sends a tapped push, or the one that started the app, to where
/// it belongs.
///
/// It sits under `MaterialApp.router`'s builder, so the banner is the app's
/// themed one and the router is the app's own.
class NotificationHost extends StatefulWidget {
  const NotificationHost({
    required this.router,
    required this.child,
    super.key,
  });

  final GoRouter router;
  final Widget child;

  @override
  State<NotificationHost> createState() => _NotificationHostState();
}

class _NotificationHostState extends State<NotificationHost> {
  final _subscriptions = <StreamSubscription<PushArrival>>[];
  late final PushTapRouter _taps = PushTapRouter(
    session: context.read<SessionController>(),
    repository: context.read<NotificationRepository>(),
    go: widget.router.go,
    push: (location) => unawaited(widget.router.push<void>(location)),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_start()));
  }

  Future<void> _start() async {
    if (!mounted) return;
    final gateway = context.read<PushGateway>();
    final registrar = context.read<PushRegistrar>();
    _subscriptions
      ..add(gateway.foregroundArrivals.listen(_showBanner))
      ..add(gateway.openedArrivals.listen((arrival) => _taps.open(arrival)));
    await registrar.start();
    final launch = await gateway.launchArrival();
    if (launch != null && mounted) await _taps.open(launch);
  }

  void _showBanner(PushArrival arrival) {
    if (!mounted) return;
    final nest = NestTheme.of(context);
    final title = arrival.title;
    final body = arrival.body;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title ?? NotificationsCopy.inboxTitle,
              style: nest.text.bodyStrong.copyWith(color: nest.colors.surface),
            ),
            if (body != null)
              Text(
                body,
                style: nest.text.caption.copyWith(color: nest.colors.surface),
              ),
          ],
        ),
        action: SnackBarAction(
          label: NotificationsCopy.openItem,
          textColor: nest.colors.surface,
          onPressed: () => unawaited(_taps.open(arrival)),
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
