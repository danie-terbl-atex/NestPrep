import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/co_parent_link.dart';
import 'home_swatch.dart';

/// A link waiting to be confirmed (household ADR-0004). The home that made the
/// code sees the question and — if they are an admin — the two answers; the
/// home that accepted sees that it is waiting, and that nothing is shared yet.
class PendingLinkCard extends StatelessWidget {
  const PendingLinkCard({
    required this.link,
    required this.childName,
    required this.canAnswer,
    required this.isBusy,
    required this.onAnswer,
    required this.onWithdraw,
    super.key,
  });

  final CoParentLink link;
  final String childName;

  /// An admin of the home that made the code.
  final bool canAnswer;
  final bool isBusy;
  final ValueChanged<bool> onAnswer;

  /// The home that accepted changes its mind before the other confirms.
  final VoidCallback onWithdraw;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final ours = link.awaitsOurConfirmation;
    return NestCard(
      variant: NestCardVariant.tinted,
      padding: const EdgeInsets.all(NestSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              NestAvatar(name: childName, color: link.ownHome.color),
              const SizedBox(width: NestSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      childName,
                      style: nest.text.title.copyWith(color: nest.colors.ink),
                    ),
                    const SizedBox(height: NestSpace.xs),
                    // Below the name rather than beside it: at 200% text a
                    // tag beside a name leaves the name no room (`FE-14`).
                    const NestTag(
                      label: TwoHomesCopy.statusPending,
                      icon: LucideIcons.hourglass,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: NestSpace.md),
          Text(
            ours
                ? TwoHomesCopy.confirmQuestion(link.otherHome.name, childName)
                : TwoHomesCopy.waitingFor(link.otherHome.name),
            style: nest.text.body.copyWith(color: nest.colors.inkSecondary),
          ),
          const SizedBox(height: NestSpace.sm),
          HomeSwatch(home: link.otherHome),
          if (ours && canAnswer) ...[
            const SizedBox(height: NestSpace.lg),
            NestButton(
              label: TwoHomesCopy.confirmYes,
              icon: LucideIcons.check,
              isLoading: isBusy,
              onPressed: isBusy ? null : () => onAnswer(true),
            ),
            const SizedBox(height: NestSpace.sm),
            NestButton(
              label: TwoHomesCopy.confirmNo,
              variant: NestButtonVariant.outline,
              onPressed: isBusy ? null : () => onAnswer(false),
            ),
          ],
          if (!ours && canAnswer) ...[
            const SizedBox(height: NestSpace.md),
            NestButton(
              label: TwoHomesCopy.withdraw,
              variant: NestButtonVariant.ghost,
              size: NestButtonSize.small,
              onPressed: isBusy ? null : onWithdraw,
            ),
          ],
        ],
      ),
    );
  }
}
