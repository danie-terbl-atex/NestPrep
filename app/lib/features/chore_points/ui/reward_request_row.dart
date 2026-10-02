import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/points_copy.dart';
import '../../household/model/member.dart';
import '../data/points_directory.dart';
import '../model/reward.dart';
import '../model/reward_request.dart';
import 'reward_icon_glyph.dart';

/// A reward a child asked for, waiting to be handed over (todos ADR-0003).
/// The stars already came off when they asked; *Not now* gives them back.
class RewardRequestRow extends StatelessWidget {
  const RewardRequestRow({
    required this.request,
    required this.child,
    required this.isBusy,
    required this.onSettle,
    super.key,
  });

  final RewardRequest request;
  final Member? child;
  final bool isBusy;
  final ValueChanged<RewardSettlement> onSettle;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final icon = request.icon ?? RewardIcon.gift;
    return NestCard(
      variant: NestCardVariant.flat,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              NestIconTile(icon: icon.glyph, tint: icon.tint),
              const SizedBox(width: NestSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.title ?? PointsCopy.kidRequestUntitled,
                      style: nest.text.bodyStrong,
                    ),
                    Text(
                      PointsCopy.requestedBy(
                        child?.displayName,
                        request.cost ?? 0,
                      ),
                      style: nest.text.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: NestSpace.md),
          Wrap(
            spacing: NestSpace.sm,
            runSpacing: NestSpace.sm,
            children: [
              NestButton(
                label: PointsCopy.settleGiven,
                icon: LucideIcons.gift,
                size: NestButtonSize.small,
                isExpanded: false,
                isLoading: isBusy,
                onPressed: isBusy
                    ? null
                    : () => onSettle(RewardSettlement.fulfil),
              ),
              NestButton(
                label: PointsCopy.settleNotNow,
                variant: NestButtonVariant.outline,
                size: NestButtonSize.small,
                isExpanded: false,
                onPressed: isBusy
                    ? null
                    : () => onSettle(RewardSettlement.decline),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
