import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/copy/vault_copy.dart';
import '../../accounts/ui/account_menu_button.dart';
import '../model/vault_lock_state.dart';
import '../state/vault_lock_controller.dart';

/// What stands in front of the vaults until the phone's own lock has been
/// passed (documents ADR-0003). It asks once on arrival, and then waits for a
/// tap — a prompt that re-opened itself every time it was dismissed would be a
/// trap, not a lock.
class VaultLockScreen extends StatefulWidget {
  const VaultLockScreen({super.key});

  @override
  State<VaultLockScreen> createState() => _VaultLockScreenState();
}

class _VaultLockScreenState extends State<VaultLockScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final lock = context.read<VaultLockController>();
      if (lock.problem == null) lock.unlock();
    });
  }

  @override
  Widget build(BuildContext context) {
    final lock = context.watch<VaultLockController>();
    final problem = lock.problem;
    final isAsking = lock.state == VaultLockState.unlocking;
    return NestScaffold(
      title: VaultCopy.homeTitle,
      leading: context.canPop()
          ? NestIconButton(
              icon: Icons.arrow_back,
              label: AppCopy.back,
              variant: NestIconButtonVariant.plain,
              onPressed: context.pop,
            )
          : null,
      trailing: const [AccountMenuButton()],
      body: ListView(
        padding: const EdgeInsets.only(bottom: NestSpace.huge),
        children: [
          const SizedBox(height: NestSpace.xxxl),
          NestRiseIn(
            child: NestCard(
              child: Column(
                children: [
                  const NestIconTile(
                    icon: Icons.lock_outline,
                    size: NestSize.mark,
                    iconSize: NestSize.iconMark,
                  ),
                  const SizedBox(height: NestSpace.xl),
                  Text(
                    VaultCopy.lockedTitle,
                    textAlign: TextAlign.center,
                    style: NestTheme.of(context).text.title,
                  ),
                  const SizedBox(height: NestSpace.sm),
                  Text(
                    VaultCopy.lockedBody,
                    textAlign: TextAlign.center,
                    style: NestTheme.of(context).text.bodySecondary,
                  ),
                  if (problem != null) ...[
                    const SizedBox(height: NestSpace.lg),
                    NestBanner(
                      message: _problemCopy(problem),
                      tone: problem == UnlockOutcome.noScreenLock
                          ? NestBannerTone.warning
                          : NestBannerTone.danger,
                    ),
                  ],
                  const SizedBox(height: NestSpace.xl),
                  NestButton(
                    label: isAsking ? VaultCopy.unlocking : VaultCopy.unlock,
                    icon: Icons.fingerprint,
                    isLoading: isAsking,
                    onPressed: isAsking ? null : lock.unlock,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _problemCopy(UnlockOutcome outcome) => switch (outcome) {
    UnlockOutcome.noScreenLock => VaultCopy.noScreenLock,
    UnlockOutcome.lockedOut => VaultCopy.lockedOut,
    UnlockOutcome.unavailable ||
    UnlockOutcome.unlocked ||
    UnlockOutcome.cancelled => VaultCopy.lockUnavailable,
  };
}
