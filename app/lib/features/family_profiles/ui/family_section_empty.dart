import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';

/// What an empty section says in its own place — the section, and the way to
/// fill it, stay on screen (`FE-08`).
class FamilySectionEmpty extends StatelessWidget {
  const FamilySectionEmpty({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Text(
      message,
      style: nest.text.bodySecondary.copyWith(color: nest.colors.inkTertiary),
    );
  }
}
