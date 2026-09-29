import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/shift_window.dart';
import '../state/offline_keeper.dart';
import '../state/shift_pass_controller.dart';
import 'off_shift_screen.dart';

/// The household as a carer kept to their booked shifts sees it: everything,
/// inside a booked shift's window, and the off-shift screen outside one
/// (nanny-hub ADR-0006). The rules keep the doors shut either way; this is so
/// the carer meets a kind screen rather than a wall of refusals (`FE-04`).
///
/// It also moves the offline keeper at the edges of the day: saving when the
/// app opens and when a window opens, and — for a carer kept to their shifts
/// — clearing what was saved when the window closes (nanny-hub ADR-0007).
class ShiftGate extends StatefulWidget {
  const ShiftGate({
    required this.isShiftOnly,
    required this.followsWindow,
    required this.savesOffline,
    required this.savesOnOpen,
    required this.child,
    super.key,
  });

  final bool isShiftOnly;

  /// Whether the edges of a booked shift move anything here: always for a
  /// carer kept to their shifts, and for any carer saving for offline.
  /// Family's window never moves.
  final bool followsWindow;

  /// Offline saving is switched on and the viewer reads the hub.
  final bool savesOffline;

  /// Save when the app opens: a carer, not family, who has signal at home.
  final bool savesOnOpen;
  final Widget child;

  @override
  State<ShiftGate> createState() => _ShiftGateState();
}

class _ShiftGateState extends State<ShiftGate> {
  ShiftPassController? _pass;
  bool? _wasOpen;

  @override
  void initState() {
    super.initState();
    if (widget.followsWindow) {
      _pass = context.read<ShiftPassController>()..addListener(_onWindow);
    }
    if (widget.savesOnOpen && !widget.isShiftOnly) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(context.read<OfflineKeeper>().open());
      });
    }
  }

  /// The edges of a booked shift's window: opening saves everything fresh for
  /// no signal; closing, for a carer kept to their shifts, takes it all back
  /// off the phone — including when the app was closed across the edge.
  void _onWindow() {
    final pass = _pass;
    if (pass == null || pass.window is! AsyncData<ShiftWindow>) return;
    final isOpen = pass.isOpen;
    final wasOpen = _wasOpen;
    _wasOpen = isOpen;
    if (wasOpen == isOpen) return;
    final keeper = context.read<OfflineKeeper>();
    if (!isOpen) {
      if (widget.isShiftOnly) unawaited(keeper.forget());
    } else if (widget.savesOffline) {
      // A carer kept to their shifts saves when the window first opens;
      // anybody else already saved when the app opened.
      if (wasOpen != null) {
        unawaited(keeper.saveNow());
      } else if (widget.isShiftOnly) {
        unawaited(keeper.open());
      }
    }
  }

  @override
  void dispose() {
    _pass?.removeListener(_onWindow);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isShiftOnly) return widget.child;
    final pass = context.watch<ShiftPassController>();
    return switch (pass.window) {
      AsyncLoading() => const NestScaffold(body: NestLoadingView()),
      AsyncFailure(:final failure) => NestScaffold(
        body: NestErrorView(
          message: AppCopy.failure(failure),
          retryLabel: AppCopy.retry,
          onRetry: pass.retry,
        ),
      ),
      AsyncData(:final value) when value.isOpen => widget.child,
      AsyncData() => OffShiftScreen(
        upcoming: pass.stillToCome,
        onCheckAgain: pass.retry,
      ),
    };
  }
}
