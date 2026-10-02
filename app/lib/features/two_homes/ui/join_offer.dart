import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/co_parent_home.dart';
import '../model/custody_side.dart';
import '../state/join_link_controller.dart';
import 'fortnight_strip.dart';
import 'home_identity_fields.dart';
import 'home_swatch.dart';
import 'privacy_boundary.dart';

/// What a checked code offers, and the three choices accepting it needs
/// (household ADR-0004): which of this home's kid profiles is the child, what
/// this home is called, and its colour — with the privacy boundary beside the
/// button, so nobody accepts without reading what crosses.
class JoinOffer extends StatelessWidget {
  const JoinOffer({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<JoinLinkController>();
    final preview = controller.preview;
    if (preview == null) return const SizedBox.shrink();
    final nest = NestTheme.of(context);
    final ours = CoParentHome(
      name: controller.homeName.trim().isEmpty
          ? TwoHomesSetupCopy.yourHome
          : controller.homeName.trim(),
      color: controller.color,
    );
    CoParentHome homeOf(CustodySide side) =>
        side == CustodySide.a ? preview.home : ours;
    final schedule = preview.schedule;
    final cycle = schedule.cycle;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NestRiseIn(
          child: NestCard(
            variant: NestCardVariant.tinted,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  TwoHomesSetupCopy.offerTitle(
                    preview.home.name,
                    preview.childName,
                  ),
                  style: nest.text.title,
                ),
                const SizedBox(height: NestSpace.sm),
                HomeSwatch(home: preview.home),
                const SizedBox(height: NestSpace.lg),
                Text(
                  '${TwoHomesSetupCopy.theirSchedule}: '
                  '${TwoHomesCopy.patternName(schedule.pattern)}',
                  style: nest.text.label.copyWith(
                    color: nest.colors.inkSecondary,
                  ),
                ),
                const SizedBox(height: NestSpace.sm),
                FortnightStrip(
                  start: schedule.startsOn,
                  sides: [
                    for (var day = 0; day < 14; day++)
                      cycle.isEmpty ? null : cycle[day % cycle.length],
                  ],
                  homeOf: homeOf,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: NestSpace.xl),
        NestSectionHeader(
          title: TwoHomesSetupCopy.yourProfileFor(preview.childName),
        ),
        const SizedBox(height: NestSpace.sm),
        Wrap(
          spacing: NestSpace.sm,
          runSpacing: NestSpace.sm,
          children: [
            for (final kid in controller.kids)
              NestChip(
                label: kid.displayName,
                isSelected: controller.childId == kid.id,
                onTap: () => controller.chooseChild(kid.id),
              ),
            NestChip(
              label: TwoHomesSetupCopy.addAsNewKid(preview.childName),
              icon: LucideIcons.plus,
              isSelected: controller.addsNewChild,
              onTap: () => controller.chooseChild(null),
            ),
          ],
        ),
        const SizedBox(height: NestSpace.xl),
        const NestSectionHeader(title: TwoHomesSetupCopy.yourHome),
        const SizedBox(height: NestSpace.sm),
        HomeIdentityFields(
          name: controller.homeName,
          color: controller.color,
          onName: controller.nameHome,
          onColor: controller.chooseColor,
        ),
        const SizedBox(height: NestSpace.xl),
        const NestSectionHeader(title: TwoHomesSetupCopy.privacyTitle),
        const SizedBox(height: NestSpace.sm),
        const PrivacyBoundary(),
        const SizedBox(height: NestSpace.xl),
        NestButton(
          label: TwoHomesSetupCopy.acceptLink,
          icon: LucideIcons.handshake,
          isLoading: controller.isBusy,
          onPressed: controller.canAccept ? controller.accept : null,
        ),
        const SizedBox(height: NestSpace.sm),
        NestButton(
          label: AppCopy.back,
          variant: NestButtonVariant.ghost,
          onPressed: controller.isBusy ? null : controller.startOver,
        ),
      ],
    );
  }
}
