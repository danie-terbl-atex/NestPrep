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
            Text('Section title', style: nest.text.title),
            Text('Stand-up', style: nest.text.titleLight),
            Text('Body copy at sixteen.', style: nest.text.body),
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
                  icon: Icons.add,
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
                  icon: Icons.menu,
                  label: 'Menu',
                  onPressed: () {},
                ),
                const SizedBox(width: NestSpace.sm),
                NestIconButton(
                  icon: Icons.notifications_outlined,
                  label: 'Alerts',
                  badge: true,
                  onPressed: () {},
                ),
                const SizedBox(width: NestSpace.sm),
                NestIconButton(
                  icon: Icons.add,
                  label: 'Add',
                  variant: NestIconButtonVariant.accent,
                  onPressed: () {},
                ),
                const SizedBox(width: NestSpace.sm),
                NestIconButton(
                  icon: Icons.settings_outlined,
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
                    icon: index == 0 ? Icons.today_outlined : null,
                    onTap: () => setState(() => _chip = index),
                  ),
              ],
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
              prefixIcon: Icons.key_outlined,
              errorText: 'That code has expired.',
            ),
            NestTextField(label: 'Disabled', hint: 'Not now', enabled: false),
          ],
        ),
      ],
    );
  }
}
