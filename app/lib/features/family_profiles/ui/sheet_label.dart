import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';

/// The small label over a group of chips in a sheet, the way the member sheet
/// labels its colours and roles.
class SheetLabel extends StatelessWidget {
  const SheetLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: NestSpace.sm),
      child: Text(
        text,
        style: nest.text.label.copyWith(color: nest.colors.inkSecondary),
      ),
    );
  }
}
