import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/notifications_copy.dart';
import '../model/inbox_item.dart';
import '../model/notification_vocabulary.dart';
import 'notification_look.dart';

class DigestPromptBanner extends StatelessWidget {
  const DigestPromptBanner({
    required this.digest,
    required this.onOpen,
    required this.onDismiss,
    super.key,
  });

  final InboxItem digest;
  final VoidCallback onOpen;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return GestureDetector(
      onVerticalDragEnd: (details) {
        if ((details.primaryVelocity ?? 0) < 0) onDismiss();
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(NestRadius.xl),
          boxShadow: nest.shadows.floating,
        ),
        child: NestCard(
          variant: NestCardVariant.flat,
          padding: const EdgeInsets.fromLTRB(
            NestSpace.lg,
            NestSpace.lg,
            NestSpace.xs,
            NestSpace.lg,
          ),
          onTap: onOpen,
          child: Row(
            children: [
              NestIconTile(
                icon: NotificationLook.categoryIcon(
                  NotificationCategory.digest,
                ),
                tint: NotificationLook.categoryTint(
                  NotificationCategory.digest,
                ),
              ),
              const SizedBox(width: NestSpace.lg),
              Expanded(child: _Words(digest: digest)),
              NestIconButton(
                icon: LucideIcons.x,
                label: NotificationsCopy.digestPromptDismiss,
                variant: NestIconButtonVariant.plain,
                onPressed: onDismiss,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Words extends StatelessWidget {
  const _Words({required this.digest});

  final InboxItem digest;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const NestEyebrow(NotificationsCopy.digestPromptEyebrow),
        const SizedBox(height: NestSpace.xs),
        Text(digest.title, style: nest.text.cardTitle),
        if (digest.body.isNotEmpty) ...[
          const SizedBox(height: NestSpace.xxs),
          Text(
            digest.body,
            style: nest.text.caption,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}
