import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../model/allergy_severity.dart';

/// How each severity is drawn, in one place so a severe allergy looks the same
/// on the family list, a profile and the allergy sheet. The icon and the label
/// carry it as well as the tone, so colour is never the only signal
/// (`FE-13`).
extension SeverityLook on AllergySeverity {
  NestTagTone get tone => switch (this) {
    AllergySeverity.mild => NestTagTone.neutral,
    AllergySeverity.moderate => NestTagTone.warning,
    AllergySeverity.severe => NestTagTone.danger,
  };

  IconData get icon => switch (this) {
    AllergySeverity.mild => LucideIcons.info,
    AllergySeverity.moderate => LucideIcons.triangleAlert,
    AllergySeverity.severe => LucideIcons.siren,
  };
}
