import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';

/// The short version of the privacy policy, in the four things a parent
/// most needs to know before they add anybody: children, health, papers and
/// location. It summarises; the documents themselves are what is agreed to.
class ConsentSummary extends StatelessWidget {
  const ConsentSummary({super.key});

  static const _points = [
    (
      Icons.child_care_outlined,
      NestTileTint.guava,
      LegalCopy.consentChildren,
      LegalCopy.consentChildrenBody,
    ),
    (
      Icons.health_and_safety_outlined,
      NestTileTint.basil,
      LegalCopy.consentHealth,
      LegalCopy.consentHealthBody,
    ),
    (
      Icons.folder_shared_outlined,
      NestTileTint.lilac,
      LegalCopy.consentDocuments,
      LegalCopy.consentDocumentsBody,
    ),
    (
      Icons.location_on_outlined,
      NestTileTint.butter,
      LegalCopy.consentLocation,
      LegalCopy.consentLocationBody,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return NestCard(
      padding: const EdgeInsets.all(NestSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (index, (icon, tint, title, body)) in _points.indexed) ...[
            if (index > 0) const SizedBox(height: NestSpace.lg),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NestIconTile(
                  icon: icon,
                  tint: tint,
                  size: NestSize.avatarMedium,
                  iconSize: NestSize.iconMedium,
                ),
                const SizedBox(width: NestSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: nest.text.bodyStrong),
                      const SizedBox(height: NestSpace.xxs),
                      Text(body, style: nest.text.bodySecondary),
                    ],
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: NestSpace.lg),
          Text(LegalCopy.consentRights, style: nest.text.caption),
        ],
      ),
    );
  }
}
