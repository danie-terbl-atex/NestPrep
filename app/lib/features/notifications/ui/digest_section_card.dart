import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/notifications_copy.dart';
import '../model/inbox_item.dart';
import 'notification_look.dart';

/// One section of a morning digest (notifications ADR-0002): its tile, its
/// title, its lines — each line's detail under it — and a way into the part
/// of the app it came from.
class DigestSectionCard extends StatelessWidget {
  const DigestSectionCard({required this.section, this.onOpen, super.key});

  final DigestSection section;

  /// Where the section's link goes; null for a section this build cannot
  /// place.
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final kind = section.sectionKind;
    return NestCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              NestIconTile(
                icon: NotificationLook.sectionIcon(kind),
                tint: NotificationLook.sectionTint(kind),
                size: NestSize.avatarMedium,
                iconSize: NestSize.iconMedium,
              ),
              const SizedBox(width: NestSpace.lg),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    NotificationsCopy.sectionTitle(kind),
                    style: nest.text.title,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: NestSpace.md),
          for (final line in section.items) _Line(line: line),
          if (kind != null && onOpen != null) ...[
            const SizedBox(height: NestSpace.sm),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: NestButton(
                label: NotificationsCopy.sectionLink(kind),
                variant: NestButtonVariant.ghost,
                size: NestButtonSize.small,
                icon: LucideIcons.arrowRight,
                isExpanded: false,
                onPressed: onOpen,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.line});

  final DigestLine line;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final detail = line.detail;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: NestSpace.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: NestSpace.sm),
            child: ExcludeSemantics(
              child: Container(
                width: NestSpace.xs + NestSpace.xxs,
                height: NestSpace.xs + NestSpace.xxs,
                decoration: BoxDecoration(
                  color: nest.colors.inkTertiary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const SizedBox(width: NestSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(line.text, style: nest.text.bodyStrong),
                if (detail != null && detail.isNotEmpty)
                  Text(detail, style: nest.text.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
