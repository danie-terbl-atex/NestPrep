import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/points_copy.dart';
import '../../household/model/member.dart';
import '../model/point_balance.dart';
import '../model/reward.dart';
import 'reward_icon_glyph.dart';

/// A parent spending a child's stars for them — for a child with no device of
/// their own (todos ADR-0003). Rewards the child cannot afford are shown and
/// not offered, with how many more stars they need; the server refuses them
/// anyway. Returns the chosen reward, or null.
Future<Reward?> showSpendForSheet({
  required BuildContext context,
  required Member child,
  required PointBalance balance,
  required List<Reward> rewards,
}) => showNestSheet<Reward>(
  context: context,
  title: PointsCopy.spendForTitle(child.displayName, balance.balance),
  builder: (sheetContext) => ListView(
    shrinkWrap: true,
    children: [
      for (final reward in rewards)
        NestListRow(
          key: ValueKey(reward.id),
          leading: NestIconTile(
            icon: reward.icon.glyph,
            tint: reward.icon.tint,
          ),
          title: reward.title,
          subtitle: balance.balance >= reward.cost
              ? PointsCopy.starsCount(reward.cost)
              : PointsCopy.needsMore(
                  reward.cost,
                  reward.cost - balance.balance,
                ),
          onTap: balance.balance >= reward.cost
              ? () => Navigator.of(sheetContext).pop(reward)
              : null,
        ),
    ],
  ),
);
