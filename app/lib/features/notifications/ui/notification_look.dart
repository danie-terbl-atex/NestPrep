import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../model/notification_vocabulary.dart';

/// How each kind of notification and each digest section looks — one glyph
/// and one tile tint apiece, so the inbox, the digest and the settings screen
/// always agree. The tint is decoration; the words beside it are the signal
/// (`FE-13`).
abstract final class NotificationLook {
  static IconData categoryIcon(NotificationCategory category) =>
      switch (category) {
        NotificationCategory.digest => Icons.wb_twilight_rounded,
        NotificationCategory.documents => Icons.description_outlined,
        NotificationCategory.handover => Icons.child_care_outlined,
        NotificationCategory.chores => Icons.star_outline_rounded,
        NotificationCategory.photos => Icons.photo_camera_outlined,
        NotificationCategory.coParenting => Icons.cottage_outlined,
        NotificationCategory.test => Icons.notifications_active_outlined,
      };

  static NestTileTint categoryTint(NotificationCategory category) =>
      switch (category) {
        NotificationCategory.digest => NestTileTint.butter,
        NotificationCategory.documents => NestTileTint.lilac,
        NotificationCategory.handover => NestTileTint.guava,
        NotificationCategory.chores => NestTileTint.basil,
        NotificationCategory.photos => NestTileTint.guava,
        NotificationCategory.coParenting => NestTileTint.butter,
        NotificationCategory.test => NestTileTint.accent,
      };

  static IconData sectionIcon(DigestSectionKind? kind) => switch (kind) {
    DigestSectionKind.events => Icons.event_outlined,
    DigestSectionKind.pack => Icons.backpack_outlined,
    DigestSectionKind.chores => Icons.check_circle_outline,
    DigestSectionKind.documents => Icons.description_outlined,
    DigestSectionKind.shift => Icons.child_care_outlined,
    DigestSectionKind.approvals => Icons.star_outline_rounded,
    null => Icons.notes_rounded,
  };

  static NestTileTint sectionTint(DigestSectionKind? kind) => switch (kind) {
    DigestSectionKind.events => NestTileTint.lilac,
    DigestSectionKind.pack => NestTileTint.butter,
    DigestSectionKind.chores => NestTileTint.basil,
    DigestSectionKind.documents => NestTileTint.accent,
    DigestSectionKind.shift => NestTileTint.guava,
    DigestSectionKind.approvals => NestTileTint.basil,
    null => NestTileTint.accent,
  };

  static IconData switchableIcon(SwitchableCategory category) =>
      switch (category) {
        SwitchableCategory.documents => Icons.description_outlined,
        SwitchableCategory.handover => Icons.child_care_outlined,
        SwitchableCategory.chores => Icons.star_outline_rounded,
        SwitchableCategory.photos => Icons.photo_camera_outlined,
        SwitchableCategory.coParenting => Icons.cottage_outlined,
      };
}
