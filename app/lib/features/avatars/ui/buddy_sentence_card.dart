import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/avatar_creation_copy.dart';
import '../model/avatar_buddy.dart';

class BuddySentenceCard extends StatelessWidget {
  const BuddySentenceCard({
    required this.buddy,
    this.isCompact = false,
    super.key,
  });

  final AvatarBuddy buddy;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Semantics(
      liveRegion: !isCompact,
      child: NestCard(
        variant: NestCardVariant.tinted,
        padding: EdgeInsets.all(isCompact ? NestSpace.md : NestSpace.xl),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              LucideIcons.wandSparkles,
              size: isCompact ? NestSize.iconSmall : NestSize.iconLarge,
              color: nest.colors.inkSecondary,
            ),
            SizedBox(width: isCompact ? NestSpace.sm : NestSpace.md),
            Expanded(
              child: Text(
                AvatarCreationCopy.buddySentence(buddy),
                style: isCompact ? nest.text.body : nest.text.title,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
