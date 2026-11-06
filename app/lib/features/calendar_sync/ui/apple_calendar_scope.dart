import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../../shared/log/best_effort.dart';
import '../../accounts/state/session_controller.dart';
import '../state/apple_calendar_sync.dart';

/// Sends this iPhone's linked calendars to the household it wraps: once when
/// it first shows, and again whenever the app comes back to the front, which
/// is when somebody has most likely just changed their calendar. The sync
/// itself skips a push when nothing changed.
///
/// It renders nothing of its own and nothing waits on it.
class AppleCalendarScope extends StatefulWidget {
  const AppleCalendarScope({
    required this.householdId,
    required this.child,
    super.key,
  });

  final String householdId;
  final Widget child;

  @override
  State<AppleCalendarScope> createState() => _AppleCalendarScopeState();
}

class _AppleCalendarScopeState extends State<AppleCalendarScope>
    with WidgetsBindingObserver {
  late final AppleCalendarSync? _sync = context.read<AppleCalendarSync?>();
  late final SessionController _session = context.read<SessionController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _push());
  }

  @override
  void didUpdateWidget(AppleCalendarScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.householdId != widget.householdId) _push();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _push();
  }

  void _push() {
    final sync = _sync;
    final uid = _session.uidOrEmpty;
    if (!mounted || sync == null || !sync.isAvailable || uid.isEmpty) return;
    unawaited(
      bestEffort(
        'apple calendar push',
        code: 'apple-calendar-push-failed',
        run: () => sync.pushIfDue(uid, widget.householdId),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
