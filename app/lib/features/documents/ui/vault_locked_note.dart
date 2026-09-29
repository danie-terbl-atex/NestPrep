import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/vault_copy.dart';

/// Said where a search's results begin while the vaults are locked: only the
/// household's papers were searched, and one tap asks the phone to open the
/// rest (documents ADR-0003). The sentence takes the card's whole width and
/// the button sits under it, so neither squeezes the other at 200% text.
class VaultLockedNote extends StatelessWidget {
  const VaultLockedNote({required this.onUnlock, super.key});

  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return NestCard(
      variant: NestCardVariant.tinted,
      padding: const EdgeInsets.all(NestSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.lock_outline,
                size: NestSize.iconMedium,
                color: nest.colors.accentInk,
              ),
              const SizedBox(width: NestSpace.md),
              Expanded(
                child: Text(
                  VaultCopy.searchLockedNote,
                  style: nest.text.bodySecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: NestSpace.md),
          NestButton(
            label: VaultCopy.unlock,
            icon: Icons.fingerprint,
            variant: NestButtonVariant.tonal,
            size: NestButtonSize.small,
            isExpanded: false,
            onPressed: onUnlock,
          ),
        ],
      ),
    );
  }
}
