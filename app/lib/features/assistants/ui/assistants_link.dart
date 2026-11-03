import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/assistants_route.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/copy/assistants_copy.dart';

/// The way to *Connected assistants* from More (assistants ADR-0001), while
/// the `assistants` switch is on.
class AssistantsLink extends StatelessWidget {
  const AssistantsLink({required this.householdId, super.key});

  final String householdId;

  @override
  Widget build(BuildContext context) {
    return NestCard(
      variant: NestCardVariant.flat,
      padding: EdgeInsets.zero,
      child: NestListRow(
        title: AssistantsCopy.title,
        subtitle: AssistantsCopy.openFromMoreBody,
        leading: const NestIconTile(
          icon: LucideIcons.bot,
          tint: NestTileTint.lilac,
        ),
        trailing: const Icon(LucideIcons.chevronRight),
        // Pushed, so back lands on More (`FE-17`).
        onTap: () => context.push(AssistantsRoute.pathFor(householdId)),
      ),
    );
  }
}
