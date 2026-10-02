import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../family_profiles/ui/family_section_card.dart';
import '../../family_profiles/ui/family_section_empty.dart';

/// How to settle the child, and anything else worth knowing — in the parent's
/// own words, at a size that reads at arm's length.
class CareNotesSection extends StatelessWidget {
  const CareNotesSection({
    required this.settling,
    required this.goodToKnow,
    required this.onEdit,
    super.key,
  });

  final String? settling;
  final String? goodToKnow;

  /// Null when the viewer may not change the card.
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final known = goodToKnow;
    return FamilySectionCard(
      icon: LucideIcons.moonStar,
      tint: NestTileTint.accent,
      title: NannyCopy.settling,
      actionLabel: NannyCopy.editSettling,
      onAction: onEdit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          switch (settling) {
            final String text => Text(text, style: nest.text.body),
            null => const FamilySectionEmpty(message: NannyCopy.noSettling),
          },
          if (known != null) ...[
            const SizedBox(height: NestSpace.lg),
            Text(
              NannyCopy.goodToKnow,
              style: nest.text.label.copyWith(color: nest.colors.inkSecondary),
            ),
            const SizedBox(height: NestSpace.xs),
            Text(known, style: nest.text.body),
          ],
        ],
      ),
    );
  }
}
