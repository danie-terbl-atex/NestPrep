import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/access_defaults.dart';
import '../model/access_grant.dart';
import '../model/access_level.dart';
import '../model/household_area.dart';
import '../model/member.dart';
import '../state/member_access_controller.dart';
import 'area_access_card.dart';

/// The body of the access editor: who this is, two quick starting points, and
/// one card per area. The cards arrive top-down once and then stay put
/// (design-system ADR-0002).
class MemberAccessEditor extends StatelessWidget {
  const MemberAccessEditor({
    required this.member,
    required this.controller,
    required this.failureMessage,
    super.key,
  });

  final Member member;
  final MemberAccessController controller;
  final String? failureMessage;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final draft = controller.draft;
    final suggested = AccessDefaults.forRole(member.role);
    final message = failureMessage;
    return ListView(
      padding: const EdgeInsets.only(bottom: NestSpace.huge),
      children: [
        NestRiseIn(
          child: NestCard(
            variant: NestCardVariant.tinted,
            child: Row(
              children: [
                NestAvatar(
                  name: member.displayName,
                  color: member.color,
                  size: NestSize.avatarLarge,
                ),
                const SizedBox(width: NestSpace.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(member.displayName, style: nest.text.title),
                      Text(
                        AccessCopy.roleName(member.role),
                        style: nest.text.label.copyWith(
                          color: nest.colors.accentInk,
                        ),
                      ),
                      const SizedBox(height: NestSpace.xs),
                      Text(
                        AccessCopy.accessIntro(member.displayName),
                        style: nest.text.caption.copyWith(
                          color: nest.colors.inkSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: NestSpace.md),
          NestBanner(
            message: message,
            tone: NestBannerTone.danger,
            actionLabel: AppCopy.back,
            onAction: controller.dismissActionFailure,
          ),
        ],
        const SizedBox(height: NestSpace.lg),
        NestRiseIn(
          index: 1,
          child: Wrap(
            spacing: NestSpace.sm,
            runSpacing: NestSpace.sm,
            children: [
              if (suggested != null)
                NestChip(
                  label: AccessCopy.accessPresetDefaults,
                  icon: LucideIcons.sparkles,
                  isSelected: draft == suggested,
                  onTap: () => controller.applyPreset(suggested),
                ),
              NestChip(
                label: AccessCopy.accessPresetNothing,
                icon: LucideIcons.eyeOff,
                isSelected: draft == _nothing,
                onTap: () => controller.applyPreset(_nothing),
              ),
            ],
          ),
        ),
        const SizedBox(height: NestSpace.lg),
        for (final (index, area) in HouseholdArea.values.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: NestSpace.md),
            child: NestRiseIn(
              // Only the cards on the first screen arrive; one scrolled to
              // later is simply there, not late (design-system ADR-0002).
              index: math.min(2 + index, _lastArrivingIndex),
              child: AreaAccessCard(
                key: ValueKey(area),
                area: area,
                level: draft.levelIn(area),
                personName: member.displayName,
                onChanged: (level) => controller.setLevel(area, level),
              ),
            ),
          ),
      ],
    );
  }

  static final _nothing = AccessGrant.uniform(AccessLevel.none);
  static const _lastArrivingIndex = 6;
}
