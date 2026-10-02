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
        NotificationCategory.digest => LucideIcons.sunset,
        NotificationCategory.documents => LucideIcons.fileText,
        NotificationCategory.handover => LucideIcons.baby,
        NotificationCategory.chores => LucideIcons.star,
        NotificationCategory.photos => LucideIcons.camera,
        NotificationCategory.coParenting => LucideIcons.house,
        NotificationCategory.test => LucideIcons.bellRing,
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
    DigestSectionKind.events => LucideIcons.calendarDays,
    DigestSectionKind.pack => LucideIcons.backpack,
    DigestSectionKind.chores => LucideIcons.circleCheck,
    DigestSectionKind.documents => LucideIcons.fileText,
    DigestSectionKind.shift => LucideIcons.baby,
    DigestSectionKind.approvals => LucideIcons.star,
    null => LucideIcons.notepadText,
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
        SwitchableCategory.documents => LucideIcons.fileText,
        SwitchableCategory.handover => LucideIcons.baby,
        SwitchableCategory.chores => LucideIcons.star,
        SwitchableCategory.photos => LucideIcons.camera,
        SwitchableCategory.coParenting => LucideIcons.house,
      };
}
