import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/avatar_creation_copy.dart';
import '../../household/model/household_view.dart';
import '../../legal/model/legal_kind.dart';
import '../../legal/ui/legal_document_screen.dart';

class CreationDisclosure extends StatelessWidget {
  const CreationDisclosure({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final canRead =
        context.read<HouseholdView?>() != null &&
        GoRouter.maybeOf(context) != null;
    return NestCard(
      variant: NestCardVariant.flat,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            LucideIcons.shieldCheck,
            size: NestSize.iconMedium,
            color: nest.colors.inkSecondary,
          ),
          const SizedBox(width: NestSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message, style: nest.text.bodySecondary),
                if (canRead)
                  NestButton(
                    label: AvatarCreationCopy.disclosureMore,
                    variant: NestButtonVariant.link,
                    isExpanded: false,
                    onPressed: () => context.push(
                      LegalDocumentScreen.pathFor(LegalKind.privacy),
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
