import 'package:flutter/material.dart';

import '../tokens/nest_spacing.dart';
import '../tokens/nest_theme.dart';
import 'nest_button.dart';
import 'nest_sheet.dart';

/// Asks before something that cannot be undone. Returns true only when the
/// person chose the action itself — dismissing the sheet is a no, so a stray
/// tap outside never removes anybody.
Future<bool?> showNestConfirm({
  required BuildContext context,
  required String title,
  required String confirmLabel,
  required String cancelLabel,
  String? message,
  bool isDangerous = false,
}) {
  return showNestSheet<bool>(
    context: context,
    title: title,
    builder: (sheetContext) {
      final nest = NestTheme.of(sheetContext);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (message != null) ...[
            Text(
              message,
              style: nest.text.body.copyWith(color: nest.colors.inkSecondary),
            ),
            const SizedBox(height: NestSpace.xl),
          ],
          NestButton(
            label: confirmLabel,
            variant: isDangerous
                ? NestButtonVariant.danger
                : NestButtonVariant.primary,
            onPressed: () => Navigator.of(sheetContext).pop(true),
          ),
          const SizedBox(height: NestSpace.sm),
          NestButton(
            label: cancelLabel,
            variant: NestButtonVariant.ghost,
            onPressed: () => Navigator.of(sheetContext).pop(false),
          ),
        ],
      );
    },
  );
}
