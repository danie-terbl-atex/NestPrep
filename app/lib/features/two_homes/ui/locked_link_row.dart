import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/co_parent_link.dart';
import 'home_swatch.dart';

/// One open link on the locked place: the other home, the child it is for,
/// and the one way out of it this viewer has.
class LockedLinkRow extends StatelessWidget {
  const LockedLinkRow({
    required this.link,
    required this.childName,
    required this.canEnd,
    required this.isBusy,
    required this.onEnd,
    required this.onWithdraw,
    required this.onDecline,
    super.key,
  });

  final CoParentLink link;
  final String childName;

  /// An admin, as on the unlocked screens.
  final bool canEnd;
  final bool isBusy;
  final VoidCallback onEnd;
  final VoidCallback onWithdraw;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final other = link.otherHome;
    final (label, action) = !link.isPending
        ? (TwoHomesCopy.endLink, onEnd)
        : link.awaitsOurConfirmation
        ? (TwoHomesCopy.confirmNo, onDecline)
        : (TwoHomesCopy.withdraw, onWithdraw);
    return NestCard(
      variant: NestCardVariant.flat,
      padding: const EdgeInsets.all(NestSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              HomeDot(home: other),
              const SizedBox(width: NestSpace.sm),
              Expanded(child: Text(other.name, style: nest.text.bodyStrong)),
            ],
          ),
          const SizedBox(height: NestSpace.xxs),
          Text(
            !link.isPending
                ? TwoHomesCopy.lockedLinkFor(childName)
                : link.awaitsOurConfirmation
                ? TwoHomesCopy.confirmQuestion(other.name, childName)
                : TwoHomesCopy.waitingFor(other.name),
            style: nest.text.caption.copyWith(color: nest.colors.inkSecondary),
          ),
          if (canEnd) ...[
            const SizedBox(height: NestSpace.sm),
            NestButton(
              label: label,
              variant: NestButtonVariant.ghost,
              size: NestButtonSize.small,
              icon: link.isPending ? null : LucideIcons.unlink,
              isLoading: isBusy,
              onPressed: isBusy ? null : action,
            ),
          ],
        ],
      ),
    );
  }
}
