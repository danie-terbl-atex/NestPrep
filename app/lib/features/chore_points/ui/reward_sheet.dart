import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/copy/points_copy.dart';
import '../model/reward.dart';
import 'reward_icon_picker.dart';

/// What the reward sheet came back with (`ENG-09`): saved, or removed. Null
/// from [showRewardSheet] means it was closed.
sealed class RewardDraft {
  const RewardDraft();
}

final class RewardSaved extends RewardDraft {
  const RewardSaved({
    required this.title,
    required this.cost,
    required this.icon,
  });

  final String title;
  final int cost;
  final RewardIcon icon;
}

final class RewardDeleted extends RewardDraft {
  const RewardDeleted();
}

Future<RewardDraft?> showRewardSheet({
  required BuildContext context,
  Reward? existing,
}) => showNestSheet<RewardDraft>(
  context: context,
  title: existing == null ? PointsCopy.rewardAdd : PointsCopy.rewardEdit,
  builder: (_) => _RewardSheetBody(existing: existing),
);

/// A treat and what it costs (todos ADR-0003). The cost is checked as it is
/// typed — a whole number from 1 to 10 000, the same bounds the rules hold —
/// and save stays off until both the name and the cost are good (`FE-10`).
class _RewardSheetBody extends StatefulWidget {
  const _RewardSheetBody({required this.existing});

  final Reward? existing;

  @override
  State<_RewardSheetBody> createState() => _RewardSheetBodyState();
}

class _RewardSheetBodyState extends State<_RewardSheetBody> {
  static const _quickCosts = [5, 10, 20, 50];

  late final _title = TextEditingController(text: widget.existing?.title);
  late final _cost = TextEditingController(
    text: '${widget.existing?.cost ?? 10}',
  );
  late RewardIcon _icon = widget.existing?.icon ?? RewardIcon.gift;

  int? get _costValue {
    final value = int.tryParse(_cost.text);
    return value != null && value >= 1 && value <= Reward.maxCost
        ? value
        : null;
  }

  @override
  void dispose() {
    _title.dispose();
    _cost.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final cost = _costValue;
    final canSave = _title.text.trim().isNotEmpty && cost != null;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          NestTextField(
            label: PointsCopy.rewardTitleLabel,
            hint: PointsCopy.rewardTitleHint,
            controller: _title,
            autofocus: widget.existing == null,
            inputFormatters: [
              LengthLimitingTextInputFormatter(Reward.maxTitleLength),
            ],
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: NestSpace.lg),
          NestTextField(
            label: PointsCopy.rewardCostLabel,
            controller: _cost,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            errorText: cost == null ? PointsCopy.rewardCostInvalid : null,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: NestSpace.sm),
          Wrap(
            spacing: NestSpace.sm,
            runSpacing: NestSpace.sm,
            children: [
              for (final quick in _quickCosts)
                NestChip(
                  label: PointsCopy.starsCount(quick),
                  icon: Icons.star_rounded,
                  isSelected: cost == quick,
                  onTap: () => setState(() => _cost.text = '$quick'),
                ),
            ],
          ),
          const SizedBox(height: NestSpace.xl),
          Text(
            PointsCopy.rewardIconLabel,
            style: nest.text.label.copyWith(color: nest.colors.inkSecondary),
          ),
          const SizedBox(height: NestSpace.sm),
          RewardIconPicker(
            selected: _icon,
            onChanged: (icon) => setState(() => _icon = icon),
          ),
          const SizedBox(height: NestSpace.xxl),
          NestButton(
            label: AppCopy.householdSave,
            onPressed: canSave
                ? () => Navigator.of(context).pop(
                    RewardSaved(title: _title.text, cost: cost, icon: _icon),
                  )
                : null,
          ),
          if (widget.existing != null) ...[
            const SizedBox(height: NestSpace.sm),
            NestButton(
              label: AppCopy.householdRemove,
              variant: NestButtonVariant.danger,
              onPressed: () => Navigator.of(context).pop(const RewardDeleted()),
            ),
          ],
        ],
      ),
    );
  }
}
