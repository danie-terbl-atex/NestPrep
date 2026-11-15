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
        const GalleryGroup(
          title: 'Brand',
          children: [
            Center(child: NestBrandMark(size: NestSize.brandMarkLarge)),
            Center(child: NestWordmark(semanticsLabel: 'NestPrep')),
            NestBrandLockup(semanticsLabel: 'NestPrep'),
            Row(
              children: [
                NestBrandMark(size: NestSize.brandMarkSmall),
                SizedBox(width: NestSpace.md),
                NestBrandMark(),
              ],
            ),
            AspectRatio(aspectRatio: 2, child: NestWaves()),
          ],
        ),
        GalleryGroup(
          title: 'Premium',
          children: [
            const Align(
              alignment: AlignmentDirectional.centerStart,
              child: NestPremiumSeal(label: 'Premium'),
            ),
            NestPremiumCard(
              title: 'nestprep Premium',
              body: 'Every part of nestprep, for everyone in The Parkers.',
              detail: 'Renews on Sun 13 Dec',
              onTap: () {},
            ),
            const NestPremiumCard(
              title: 'nestprep Premium',
              body: 'Every part of nestprep, for everyone in The Parkers.',
            ),
          ],
        ),
        GalleryGroup(
          title: 'Twig, the AI mascot',
          children: [
            Wrap(
              spacing: NestSpace.md,
              runSpacing: NestSpace.md,
              children: [
                for (final pose in NestTwigPose.values)
                  NestTwig(pose: pose, size: NestSize.twigLarge),
              ],
            ),
            const Row(
              children: [
                NestTwig(pose: NestTwigPose.waving, size: NestSize.twigSmall),
                SizedBox(width: NestSpace.md),
                NestTwig(pose: NestTwigPose.thinking),
              ],
            ),
          ],
        ),
        GalleryGroup(
          title: 'Cards',
          children: [
            NestCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  NestSectionHeader(
                    title: "Today's plan",
                    actionIcon: LucideIcons.plus,
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
              leading: const NestIconTile(icon: LucideIcons.shoppingBasket),
              title: 'Groceries',
              subtitle: '4 things to buy',
              trailing: Icon(
                LucideIcons.chevronRight,
                color: nest.colors.inkTertiary,
              ),
              onTap: () {},
            ),
            NestListRow(
              leading: const NestIconTile(
                icon: LucideIcons.listChecks,
                tint: NestTileTint.basil,
              ),
              title: 'Laundry day',
              subtitle: 'Routine · Saturdays',
              onTap: () {},
            ),
            NestListRow(
              leading: const NestIconTile(
                icon: LucideIcons.fileText,
                tint: NestTileTint.butter,
              ),
              title: 'Passport',
              subtitle: 'A row with badges under it',
              footer: const Wrap(
                spacing: NestSpace.xs,
                runSpacing: NestSpace.xs,
                children: [
                  NestBadge(
                    label: 'Expired',
                    tone: NestBadgeTone.danger,
                    icon: LucideIcons.circleAlert,
                  ),
                  NestBadge(
                    label: 'Expires in 12 days',
                    tone: NestBadgeTone.warning,
                    icon: LucideIcons.clock,
                  ),
                  NestBadge(label: 'Coming up', tone: NestBadgeTone.info),
                  NestBadge(label: 'ID', icon: LucideIcons.tag),
                ],
              ),
              onTap: () {},
            ),
            const Wrap(
              spacing: NestSpace.md,
              runSpacing: NestSpace.md,
              children: [
                NestIconTile(icon: LucideIcons.pencil, label: 'Create'),
                NestIconTile(
                  icon: LucideIcons.calendarDays,
                  tint: NestTileTint.lilac,
                  label: 'Plan',
                ),
                NestIconTile(
                  icon: LucideIcons.utensils,
                  tint: NestTileTint.butter,
                  label: 'Meals',
                ),
                NestIconTile(
                  icon: LucideIcons.heart,
                  tint: NestTileTint.guava,
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
            Wrap(
              spacing: NestSpace.xl,
              runSpacing: NestSpace.xl,
              crossAxisAlignment: WrapCrossAlignment.end,
              children: [
                for (final (size, layers) in const [
                  (NestSize.avatarSmall, <NestAvatarSlot>[]),
                  (NestSize.avatarMedium, [NestAvatarSlot.top]),
                  (
                    NestSize.avatarLarge,
                    [NestAvatarSlot.top, NestAvatarSlot.badge],
                  ),
                  (
                    NestSize.mark,
                    [
                      NestAvatarSlot.ring,
                      NestAvatarSlot.top,
                      NestAvatarSlot.badge,
                    ],
                  ),
                ])
                  NestAvatar(
                    name: 'Pip',
                    color: MemberColor.coral,
                    size: size,
                    picture: const AssetImage(
                      'assets/avatars/nestling-pip-2.webp',
                    ),
                    layers: [
                      for (final slot in layers)
                        NestAvatarLayer(
                          slot: slot,
                          image: AssetImage(switch (slot) {
                            NestAvatarSlot.top =>
                              'assets/avatars/acc-crown.webp',
                            NestAvatarSlot.badge =>
                              'assets/avatars/acc-football.webp',
                            _ => 'assets/avatars/acc-star-ring.webp',
                          }),
                        ),
                    ],
                  ),
                NestEditablePicture(
                  label: 'Change picture',
                  onTap: () {},
                  child: const NestAvatar(
                    name: 'Olive',
                    color: MemberColor.mint,
                    size: NestSize.mark,
                    layers: [
                      NestAvatarLayer(
                        slot: NestAvatarSlot.top,
                        image: AssetImage('assets/avatars/acc-party-hat.webp'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(
              width: NestSize.cropperMax,
              child: NestPickGrid(
                children: [
                  for (final (index, name) in const [
                    'pip',
                    'olive',
                    'sunny',
                  ].indexed)
                    NestPickTile(
                      label: name,
                      isSelected: index == 0,
                      onTap: () {},
                      picture: Image.asset(
                        'assets/avatars/nestling-$name-1.webp',
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        GalleryGroup(
          title: 'Photo and motion',
          children: [
            const NestEyebrow("Monday's little win"),
            Text('The happy crunch box', style: nest.text.screenTitle),
            NestPhotoCard(
              heroTag: 'gallery-photo',
              actionLabel: 'View lunch',
              actionIcon: LucideIcons.arrowUpRight,
              onTap: () {},
              photo: ColoredBox(
                color: nest.colors.tileGuava,
                child: const Center(
                  child: NestBrandMark(size: NestSize.brandMarkLarge),
                ),
              ),
            ),
            NestPhotoHero(
              backLabel: 'Back',
              onBack: () {},
              photo: ColoredBox(color: nest.colors.tileButter),
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
