import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../state/activity_heartbeat.dart';

/// Counts the household it wraps as opened: once when it first shows, and
/// again whenever the app comes back to the front (product-analytics
/// ADR-0001). The heartbeat keeps that to once a day.
///
/// It sits in the household shell, below the point where the household has
/// loaded, so it only ever counts a household the account is really in — and
/// switching household is a new scope counting the new one.
///
/// It renders nothing of its own and nothing waits on it.
class HouseholdActivityScope extends StatefulWidget {
  const HouseholdActivityScope({
    required this.householdId,
    required this.child,
    super.key,
  });

  final String householdId;
  final Widget child;

  @override
  State<HouseholdActivityScope> createState() => _HouseholdActivityScopeState();
}

class _HouseholdActivityScopeState extends State<HouseholdActivityScope>
    with WidgetsBindingObserver {
  late final ActivityHeartbeat _heartbeat = context.read<ActivityHeartbeat>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Off the frame: a build is not where side effects belong (`FE-05`).
    WidgetsBinding.instance.addPostFrameCallback((_) => _beat());
  }

  @override
  void didUpdateWidget(HouseholdActivityScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.householdId != widget.householdId) _beat();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _beat();
  }

  void _beat() {
    if (!mounted) return;
    unawaited(_heartbeat.beat(widget.householdId));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
