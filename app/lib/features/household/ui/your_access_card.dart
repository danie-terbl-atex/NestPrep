import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/household_area.dart';
import '../model/household_permissions.dart';
import 'area_tile.dart';

/// For a kid, helper or carer: the areas a parent opened to them, and how
/// far — so what they can use is said rather than discovered by what is
/// missing (household ADR-0003).
class YourAccessCard extends StatelessWidget {
  const YourAccessCard({required this.permissions, super.key});

  final HouseholdPermissions permissions;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final open = [
      for (final area in HouseholdArea.values)
        if (permissions.canUse(area)) area,
    ];
    return NestCard(
      variant: NestCardVariant.tinted,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(AccessCopy.peopleYourAccessTitle, style: nest.text.title),
          const SizedBox(height: NestSpace.xs),
          Text(
            AccessCopy.peopleYourAccessBody,
            style: nest.text.caption.copyWith(color: nest.colors.inkSecondary),
          ),
          const SizedBox(height: NestSpace.md),
          if (open.isEmpty)
            Text(
              AccessCopy.accessSummary(const []),
              style: nest.text.body.copyWith(color: nest.colors.inkSecondary),
            ),
          for (final area in open)
            Padding(
              padding: const EdgeInsets.only(bottom: NestSpace.sm),
              child: Row(
                children: [
                  AreaTile(area: area),
                  const SizedBox(width: NestSpace.md),
                  Expanded(
                    child: Text(
                      AccessCopy.areaName(area),
                      style: nest.text.bodyStrong,
                    ),
                  ),
                  Text(
                    AccessCopy.levelName(permissions.levelIn(area)),
                    style: nest.text.label.copyWith(
                      color: nest.colors.accentInk,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
