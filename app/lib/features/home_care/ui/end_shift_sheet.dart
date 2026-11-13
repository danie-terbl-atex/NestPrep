import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';

/// Asks before a shift is clocked out — the end is the server's time and
/// cannot be moved afterwards (home-care ADR-0007). True to end it.
Future<bool> showEndHelperShiftSheet({
  required BuildContext context,
  required String title,
  required String body,
}) async {
  final ends = await showNestSheet<bool>(
    context: context,
    title: title,
    builder: (context) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(body, style: NestTheme.of(context).text.bodySecondary),
        const SizedBox(height: NestSpace.xxl),
        NestButton(
          label: HomeCareShiftCopy.endShift,
          icon: LucideIcons.logOut,
          onPressed: () => Navigator.of(context).pop(true),
        ),
        const SizedBox(height: NestSpace.sm),
        NestButton(
          label: HomeCareShiftCopy.cancel,
          variant: NestButtonVariant.ghost,
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ],
    ),
  );
  return ends ?? false;
}
