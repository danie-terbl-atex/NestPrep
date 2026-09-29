import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';

/// "Available offline" — a word and an icon, never a colour alone (`FE-13`),
/// on a document kept on this phone (documents ADR-0007).
class OfflineBadge extends StatelessWidget {
  const OfflineBadge({super.key});

  @override
  Widget build(BuildContext context) => const NestTag(
    label: OfflineCopiesCopy.badge,
    icon: Icons.offline_pin_outlined,
    tone: NestTagTone.success,
  );
}
