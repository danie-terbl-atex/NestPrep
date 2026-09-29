import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../design/nest_kit.dart';
import '../../../../shared/copy/app_copy.dart';
import '../../model/lunch_board.dart';
import '../../model/lunch_card_format.dart';
import '../../model/lunch_card_naming.dart';
import '../../state/lunch_share_controller.dart';
import 'lunch_card_style_picker.dart';

/// Everything the parent chooses about a card, top to bottom: whose week,
/// its shape, its look, how children are named — with the promise that
/// allergies and schools never go on it — and the invite line
/// (lunch-box ADR-0005).
class LunchCardChoices extends StatelessWidget {
  const LunchCardChoices({required this.board, super.key});

  final LunchBoard board;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final controller = context.watch<LunchShareController>();
    final options = controller.options;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (board.children.length > 1) ...[
          const NestSectionHeader(title: LunchShareCopy.whose),
          _ChipRow(
            children: [
              for (final child in board.children)
                NestChip(
                  label: child.child.member.displayName,
                  isSelected: options.childId == child.childId,
                  onTap: () => controller.chooseChild(child.childId),
                ),
              NestChip(
                label: LunchShareCopy.everyone,
                icon: Icons.groups_rounded,
                isSelected: options.isFamily,
                onTap: () => controller.chooseChild(null),
              ),
            ],
          ),
          const SizedBox(height: NestSpace.lg),
        ],
        const NestSectionHeader(title: LunchShareCopy.shape),
        _ChipRow(
          children: [
            for (final format in LunchCardFormat.values)
              NestChip(
                label: LunchShareCopy.formatName(format),
                isSelected: options.format == format,
                onTap: () => controller.chooseFormat(format),
              ),
          ],
        ),
        const SizedBox(height: NestSpace.xs),
        Text(
          LunchShareCopy.formatHint(options.format),
          style: nest.text.caption,
        ),
        const SizedBox(height: NestSpace.lg),
        const NestSectionHeader(title: LunchShareCopy.look),
        LunchCardStylePicker(
          selected: options.style,
          onSelect: controller.chooseStyle,
        ),
        const SizedBox(height: NestSpace.lg),
        const NestSectionHeader(title: LunchShareCopy.names),
        _ChipRow(
          children: [
            for (final naming in const [
              LunchCardNaming.initials,
              LunchCardNaming.none,
              LunchCardNaming.firstNames,
            ])
              NestChip(
                label: LunchShareCopy.namingName(naming),
                isSelected: options.naming == naming,
                onTap: () => controller.chooseNaming(naming),
              ),
          ],
        ),
        const SizedBox(height: NestSpace.sm),
        const NestToneRow(
          tone: NestTagTone.accent,
          icon: Icons.shield_outlined,
          title: LunchShareCopy.privacyTitle,
          subtitle: LunchShareCopy.privacyNote,
        ),
        const SizedBox(height: NestSpace.md),
        NestListRow(
          title: LunchShareCopy.invite,
          subtitle: LunchShareCopy.inviteHint,
          trailing: Switch(
            value: options.showsInvite,
            onChanged: (value) => controller.setShowsInvite(showsInvite: value),
          ),
          onTap: () =>
              controller.setShowsInvite(showsInvite: !options.showsInvite),
        ),
      ],
    );
  }
}

class _ChipRow extends StatelessWidget {
  const _ChipRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: NestSpace.xs),
    child: Wrap(
      spacing: NestSpace.sm,
      runSpacing: NestSpace.sm,
      children: children,
    ),
  );
}
