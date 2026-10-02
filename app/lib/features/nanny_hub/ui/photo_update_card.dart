import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import 'nanny_photo.dart';

/// One photo in the parents' feed: the picture first and big, then the words
/// the carer sent with it, who sent it and when, and which children are in
/// it. It renders what it is given and reports a take-back (`FE-03`).
class PhotoUpdateCard extends StatelessWidget {
  const PhotoUpdateCard({
    required this.photoId,
    required this.caption,
    required this.byline,
    required this.childNames,
    required this.onRemove,
    super.key,
  });

  final String photoId;
  final String? caption;

  /// "From Nomsa at 14:32".
  final String byline;
  final List<String> childNames;

  /// Null when the viewer may not take it back.
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final words = caption;
    final remove = onRemove;
    return NestCard(
      padding: const EdgeInsets.all(NestSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NannyPhoto(photoId: photoId, label: NannyPhotoCopy.photoOf(words)),
          const SizedBox(height: NestSpace.md),
          if (words != null) ...[
            Text(words, style: nest.text.bodyStrong),
            const SizedBox(height: NestSpace.xs),
          ],
          Row(
            children: [
              Expanded(child: Text(byline, style: nest.text.bodySecondary)),
              if (remove != null)
                NestIconButton(
                  icon: LucideIcons.undo2,
                  label: NannyPhotoCopy.remove,
                  variant: NestIconButtonVariant.plain,
                  onPressed: remove,
                ),
            ],
          ),
          if (childNames.isNotEmpty) ...[
            const SizedBox(height: NestSpace.xs),
            Wrap(
              spacing: NestSpace.xs,
              runSpacing: NestSpace.xs,
              children: [for (final name in childNames) NestTag(label: name)],
            ),
          ],
        ],
      ),
    );
  }
}
