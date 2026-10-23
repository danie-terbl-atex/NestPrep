import 'package:flutter/material.dart';

import '../nest_kit.dart';
import 'gallery_group.dart';

class GalleryControlsSection extends StatefulWidget {
  const GalleryControlsSection({super.key});

  @override
  State<GalleryControlsSection> createState() => _GalleryControlsSectionState();
}

class _GalleryControlsSectionState extends State<GalleryControlsSection> {
  int _chip = 0;
  int _segment = 0;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GalleryGroup(
          title: 'Type',
          children: [
            Text('Hello, Alex', style: nest.text.display),
            Text('How may I help?', style: nest.text.headline),
            Text('Screen title', style: nest.text.screenTitle),
            Text('Card title', style: nest.text.title),
            Text('Bobotie', style: nest.text.cardTitle),
            Text('4 812', style: nest.text.figure),
            Text('Stand-up', style: nest.text.titleLight),
            Text('Body copy at sixteen.', style: nest.text.body),
            Text(
              'A method step, read at arm’s length.',
              style: nest.text.reading,
            ),
            Text('Secondary body copy.', style: nest.text.bodySecondary),
            Text('Label', style: nest.text.label),
            Text('Caption · 2 min ago', style: nest.text.caption),
          ],
        ),
        GalleryGroup(
          title: 'Buttons',
          children: [
            for (final variant in NestButtonVariant.values)
              NestButton(
                label: variant.name,
                variant: variant,
                isLoading: _loading && variant == NestButtonVariant.primary,
                onPressed: () => setState(() => _loading = !_loading),
              ),
            const NestButton(label: 'disabled', onPressed: null),
            Row(
              children: [
                NestButton(
                  label: 'small',
                  size: NestButtonSize.small,
                  isExpanded: false,
                  icon: LucideIcons.plus,
                  onPressed: () {},
                ),
                const SizedBox(width: NestSpace.sm),
                NestButton(
                  label: 'medium',
                  size: NestButtonSize.medium,
                  variant: NestButtonVariant.tonal,
                  isExpanded: false,
                  onPressed: () {},
                ),
              ],
            ),
          ],
        ),
        GalleryGroup(
          title: 'Icon buttons',
          children: [
            Row(
              children: [
                NestIconButton(
                  icon: LucideIcons.menu,
                  label: 'Menu',
                  onPressed: () {},
                ),
                const SizedBox(width: NestSpace.sm),
                NestIconButton(
                  icon: LucideIcons.bell,
                  label: 'Alerts',
                  badge: true,
                  onPressed: () {},
                ),
                const SizedBox(width: NestSpace.sm),
                NestIconButton(
                  icon: LucideIcons.plus,
                  label: 'Add',
                  variant: NestIconButtonVariant.accent,
                  onPressed: () {},
                ),
                const SizedBox(width: NestSpace.sm),
                NestIconButton(
                  icon: LucideIcons.settings,
                  label: 'Settings',
                  variant: NestIconButtonVariant.plain,
                  onPressed: () {},
                ),
              ],
            ),
          ],
        ),
        GalleryGroup(
          title: 'Chips',
          children: [
            Wrap(
              spacing: NestSpace.sm,
              runSpacing: NestSpace.sm,
              children: [
                for (final (index, label) in [
                  'Today',
                  'Week',
                  'Mine',
                  'All',
                ].indexed)
                  NestChip(
                    label: label,
                    isSelected: index == _chip,
                    icon: index == 0 ? LucideIcons.calendarCheck : null,
                    onTap: () => setState(() => _chip = index),
                  ),
              ],
            ),
          ],
        ),
        GalleryGroup(
          title: 'Segmented control',
          children: [
            NestSegmentedControl<int>(
              segments: const [
                NestSegment(value: 0, label: 'Recipes'),
                NestSegment(value: 1, label: 'This week'),
              ],
              selected: _segment,
              onSelect: (value) => setState(() => _segment = value),
            ),
          ],
        ),
        GalleryGroup(
          title: 'Steps',
          children: [
            const NestStepsBar(
              count: 3,
              index: 1,
              label: 'Step 2 of 3: Review',
            ),
            NestStepActions(
              nextLabel: 'Fill the week',
              nextIcon: LucideIcons.check,
              onNext: () {},
              secondaryLabel: 'Skip — fill it all for me',
              onSecondary: () {},
              backLabel: 'Back',
              onBack: () {},
            ),
          ],
        ),
        const GalleryGroup(
          title: 'Fields',
          children: [
            NestTextField(label: 'Household name', hint: 'The Snymans'),
            NestTextField(
              label: 'Invite code',
              hint: 'ABC-123',
              prefixIcon: LucideIcons.keyRound,
              errorText: 'That code has expired.',
            ),
            NestTextField(label: 'Disabled', hint: 'Not now', enabled: false),
          ],
        ),
      ],
    );
  }
}
