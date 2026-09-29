import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';

/// What an empty part of a hub screen says, in its own place in the list —
/// the section, its heading and the button that fills it stay where they are
/// (`FE-08`). The kit's `NestEmptyView` is for a whole screen with nothing on
/// it; this is one card among others.
class HubEmptyNote extends StatelessWidget {
  const HubEmptyNote({
    required this.icon,
    required this.title,
    required this.message,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return NestCard(
      variant: NestCardVariant.flat,
      padding: const EdgeInsets.all(NestSpace.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NestIconTile(
            icon: icon,
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
                Text(message, style: nest.text.bodySecondary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
