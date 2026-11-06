import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/photo_frame_copy.dart';
import '../../household/model/member.dart';
import '../../subscriptions/state/household_entitlement.dart';
import '../model/frame_panels.dart';

class FramePanelsEditor extends StatelessWidget {
  const FramePanelsEditor({
    required this.panels,
    required this.helpers,
    required this.onChanged,
    super.key,
  });

  final FramePanels panels;
  final List<Member> helpers;
  final ValueChanged<FramePanels>? onChanged;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final change = onChanged;
    final helperId = panels.helperMemberId;
    final premium = context.watch<HouseholdEntitlement?>()?.isPremium ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(PhotoFrameCopy.showsTitle, style: nest.text.label),
        const SizedBox(height: NestSpace.sm),
        _PanelRow(
          icon: LucideIcons.calendarDays,
          tint: NestTileTint.basil,
          title: PhotoFrameCopy.calendar,
          subtitle: PhotoFrameCopy.calendarBody,
          value: panels.calendar,
          onChanged: change == null
              ? null
              : (value) => change(panels.copyWith(calendar: value)),
        ),
        _PanelRow(
          icon: LucideIcons.calendarPlus,
          tint: NestTileTint.basil,
          title: PhotoFrameCopy.addEvents,
          subtitle: PhotoFrameCopy.addEventsBody,
          value: panels.calendar && panels.addEvents,
          onChanged: change == null || !panels.calendar
              ? null
              : (value) => change(panels.copyWith(addEvents: value)),
        ),
        _PanelRow(
          icon: LucideIcons.listChecks,
          tint: NestTileTint.guava,
          title: PhotoFrameCopy.todos,
          subtitle: PhotoFrameCopy.todosBody,
          value: panels.todos,
          onChanged: change == null
              ? null
              : (value) => change(panels.copyWith(todos: value)),
        ),
        _PanelRow(
          icon: LucideIcons.utensils,
          tint: NestTileTint.butter,
          title: PhotoFrameCopy.meals,
          subtitle: PhotoFrameCopy.mealsBody,
          value: panels.meals,
          onChanged: change == null
              ? null
              : (value) => change(panels.copyWith(meals: value)),
        ),
        _PanelRow(
          icon: LucideIcons.sandwich,
          tint: NestTileTint.accent,
          title: PhotoFrameCopy.lunch,
          subtitle: PhotoFrameCopy.lunchBody,
          value: panels.lunch,
          onChanged: change == null
              ? null
              : (value) => change(panels.copyWith(lunch: value)),
        ),
        _PanelRow(
          icon: LucideIcons.mapPin,
          tint: NestTileTint.lilac,
          title: PhotoFrameCopy.people,
          subtitle: PhotoFrameCopy.peopleBody,
          value: premium && panels.people,
          onChanged: change == null || !premium
              ? null
              : (value) => change(panels.copyWith(people: value)),
          footer: premium
              ? null
              : Text(
                  PhotoFrameCopy.peopleNeedsPremium,
                  style: nest.text.caption,
                ),
        ),
        if (helpers.isNotEmpty) ...[
          _PanelRow(
            icon: LucideIcons.sprayCan,
            tint: NestTileTint.lilac,
            title: PhotoFrameCopy.helperTitle,
            subtitle: PhotoFrameCopy.helperBody,
            value: helperId != null,
            onChanged: change == null
                ? null
                : (value) => change(
                    panels.copyWith(
                      helperMemberId: value ? helpers.first.id : null,
                    ),
                  ),
          ),
          if (helperId != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                NestSpace.lg,
                NestSpace.xs,
                NestSpace.lg,
                NestSpace.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(PhotoFrameCopy.chooseHelper, style: nest.text.caption),
                  const SizedBox(height: NestSpace.sm),
                  Wrap(
                    spacing: NestSpace.sm,
                    runSpacing: NestSpace.sm,
                    children: [
                      for (final helper in helpers)
                        NestChip(
                          key: ValueKey(helper.id),
                          label: helper.displayName,
                          isSelected: helper.id == helperId,
                          onTap: change == null
                              ? null
                              : () => change(
                                  panels.copyWith(helperMemberId: helper.id),
                                ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
        ],
        _PanelRow(
          icon: LucideIcons.share2,
          tint: NestTileTint.basil,
          title: PhotoFrameCopy.share,
          subtitle: PhotoFrameCopy.shareBody,
          value: panels.share,
          onChanged: change == null
              ? null
              : (value) => change(panels.copyWith(share: value)),
        ),
      ],
    );
  }
}

class _PanelRow extends StatelessWidget {
  const _PanelRow({
    required this.icon,
    required this.tint,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.footer,
  });

  final IconData icon;
  final NestTileTint tint;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final change = onChanged;
    return NestListRow(
      title: title,
      subtitle: subtitle,
      footer: footer,
      leading: NestIconTile(
        icon: icon,
        tint: tint,
        size: NestSize.avatarMedium,
      ),
      trailing: Semantics(
        label: title,
        child: Switch(value: value, onChanged: change),
      ),
      onTap: change == null ? null : () => change(!value),
    );
  }
}
