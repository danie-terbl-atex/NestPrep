import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../../shared/log/best_effort.dart';
import '../data/notification_repository.dart';
import '../model/push_arrival.dart';
import '../state/push_registrar.dart';
import '../state/turn_on_notifications.dart';

/// Shows the phone's notification prompt the first time somebody opens a
/// household on a phone that has never answered it (notifications ADR-0006).
/// It goes through [turnOnNotifications], so a yes writes the person's
/// first-time choices exactly as the inbox card's tap does.
///
/// It waits while [isHeld] — a new household's setup step is open — so the
/// question comes after the payoff, not in the middle of setting up
/// (onboarding ADR-0001).
class FirstOpenPushPrompt extends StatefulWidget {
  const FirstOpenPushPrompt({
    required this.owner,
    required this.child,
    this.isHeld = false,
    super.key,
  });

  final NotificationsOwner owner;
  final Widget child;
  final bool isHeld;

  @override
  State<FirstOpenPushPrompt> createState() => _FirstOpenPushPromptState();
}

class _FirstOpenPushPromptState extends State<FirstOpenPushPrompt> {
  late final PushRegistrar _registrar = context.read<PushRegistrar>();
  bool _asked = false;

  @override
  void initState() {
    super.initState();
    _registrar.addListener(_askIfNeverAsked);
    WidgetsBinding.instance.addPostFrameCallback((_) => _askIfNeverAsked());
  }

  @override
  void didUpdateWidget(FirstOpenPushPrompt oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.owner.memberId != widget.owner.memberId ||
        (oldWidget.isHeld && !widget.isHeld)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _askIfNeverAsked());
    }
  }

  void _askIfNeverAsked() {
    if (!mounted || _asked || widget.isHeld) return;
    if (widget.owner.memberId.isEmpty) return;
    if (_registrar.permission != PushPermission.notAsked) return;
    _asked = true;
    final repository = context.read<NotificationRepository>();
    unawaited(
      bestEffort(
        'push permission',
        code: 'firstOpen',
        run: () => turnOnNotifications(
          registrar: _registrar,
          repository: repository,
          owner: widget.owner,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _registrar.removeListener(_askIfNeverAsked);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
