import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/vault_lock_controller.dart';
import 'vault_lock_screen.dart';

/// Every vault screen sits behind this: the lock screen until the phone's own
/// lock has been passed, the screen itself after (documents ADR-0003).
///
/// It wraps the route, above the screen's own controller, so locking — from
/// the background, the five-minute timer or the button — disposes whatever the
/// screen was holding rather than leaving it in memory behind the lock.
class VaultGate extends StatelessWidget {
  const VaultGate({required this.builder, super.key});

  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    final isUnlocked = context.select<VaultLockController, bool>(
      (lock) => lock.isUnlocked,
    );
    return isUnlocked ? builder(context) : const VaultLockScreen();
  }
}
