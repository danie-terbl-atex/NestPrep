import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/kid_routes.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/copy/kid_copy.dart';

/// The way from the household screen to kid sign-in (accounts ADR-0003). It
/// sits with the people rather than in the bottom bar, and says what it is
/// before it is tapped.
class KidSignInLink extends StatelessWidget {
  const KidSignInLink({required this.householdId, super.key});

  final String householdId;

  @override
  Widget build(BuildContext context) {
    return NestCard(
      variant: NestCardVariant.flat,
      padding: EdgeInsets.zero,
      child: NestListRow(
        title: KidCopy.manageEntry,
        subtitle: KidCopy.manageEntryBody,
        leading: const NestIconTile(
          icon: LucideIcons.baby,
          tint: NestTileTint.butter,
        ),
        trailing: const Icon(LucideIcons.chevronRight),
        // Pushed, so back lands on the household screen (`FE-17`).
        onTap: () => context.push(KidRoute.managePathFor(householdId)),
      ),
    );
  }
}
