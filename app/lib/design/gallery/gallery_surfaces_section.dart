import 'package:flutter/material.dart';

import '../nest_kit.dart';
import 'gallery_group.dart';

class GallerySurfacesSection extends StatelessWidget {
  const GallerySurfacesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GalleryGroup(
          title: 'Cards',
          children: [
            NestCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  NestSectionHeader(
                    title: "Today's plan",
                    actionIcon: Icons.add,
                    actionLabel: 'Add',
                    onAction: () {},
                  ),
                  const SizedBox(height: NestSpace.sm),
                  NestListRow(
                    title: 'Stand-up',
                    titleStyle: nest.text.titleLight,
                    trailing: Text('09:30', style: nest.text.bodyStrong),
                  ),
                  NestListRow(
                    title: 'Design',
                    titleStyle: nest.text.titleLight,
                    isSelected: true,
                    trailing: Text('11:00', style: nest.text.bodyStrong),
                  ),
                ],
              ),
            ),
            const NestCard(
              variant: NestCardVariant.tinted,
              child: Text('A tinted card for a selected or tonal panel.'),
            ),
            NestCard(
              variant: NestCardVariant.flat,
              onTap: () {},
              child: const Text('A flat, tappable card.'),
            ),
          ],
        ),
        GalleryGroup(
          title: 'Rows and tiles',
          children: [
            NestListRow(
              leading: const NestIconTile(icon: Icons.shopping_basket_outlined),
              title: 'Groceries',
              subtitle: '4 things to buy',
              trailing: Icon(
                Icons.chevron_right,
                color: nest.colors.inkTertiary,
              ),
              onTap: () {},
            ),
            NestListRow(
              leading: const NestIconTile(
                icon: Icons.checklist_outlined,
                tint: NestTileTint.mint,
              ),
              title: 'Laundry day',
              subtitle: 'Routine · Saturdays',
              onTap: () {},
            ),
            const Wrap(
              spacing: NestSpace.md,
              runSpacing: NestSpace.md,
              children: [
                NestIconTile(icon: Icons.edit_outlined, label: 'Create'),
                NestIconTile(
                  icon: Icons.calendar_month_outlined,
                  tint: NestTileTint.sky,
                  label: 'Plan',
                ),
                NestIconTile(
                  icon: Icons.restaurant_outlined,
                  tint: NestTileTint.peach,
                  label: 'Meals',
                ),
                NestIconTile(
                  icon: Icons.favorite_outline,
                  tint: NestTileTint.pink,
                  label: 'Family',
                ),
              ],
            ),
          ],
        ),
        GalleryGroup(
          title: 'Members',
          children: [
            Wrap(
              spacing: NestSpace.md,
              runSpacing: NestSpace.md,
              children: [
                for (final color in MemberColor.values)
                  NestAvatar(
                    name: color.name,
                    color: color,
                    isHighlighted: color == MemberColor.violet,
                  ),
              ],
            ),
          ],
        ),
        GalleryGroup(
          title: 'Welcome',
          children: [
            const NestOrbit(
              semanticsLabel: 'An orbit of household things',
              centre: NestIconTile(
                icon: Icons.home_rounded,
                size: 72,
                iconSize: NestSize.iconTile,
              ),
              items: [
                NestOrbitItem(
                  ring: NestOrbitRing.inner,
                  turns: 0.1,
                  child: NestIconTile(icon: Icons.calendar_month_outlined),
                ),
                NestOrbitItem(
                  ring: NestOrbitRing.inner,
                  turns: 0.6,
                  child: NestIconTile(
                    icon: Icons.restaurant_outlined,
                    tint: NestTileTint.peach,
                  ),
                ),
                NestOrbitItem(
                  ring: NestOrbitRing.outer,
                  turns: 0.35,
                  child: NestAvatar(name: 'A', color: MemberColor.coral),
                ),
                NestOrbitItem(
                  ring: NestOrbitRing.outer,
                  turns: 0.85,
                  child: NestAvatar(name: 'M', color: MemberColor.teal),
                ),
              ],
            ),
            NestTypewriterText(
              text: 'A line that types itself out, once.',
              style: nest.text.body,
            ),
            NestRiseIn(
              index: 1,
              child: NestCard(
                variant: NestCardVariant.tinted,
                child: Text(
                  'And a card that rises in behind it.',
                  style: nest.text.bodySecondary,
                ),
              ),
            ),
          ],
        ),
        GalleryGroup(
          title: 'Sheet',
          children: [
            NestButton(
              label: 'Open a sheet',
              variant: NestButtonVariant.outline,
              onPressed: () => showNestSheet<void>(
                context: context,
                title: 'Add a grocery',
                builder: (context) => const NestTextField(
                  label: 'Item',
                  hint: 'Milk',
                  autofocus: true,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
