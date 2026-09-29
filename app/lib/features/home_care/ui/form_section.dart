import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';

/// One part of the job form: its label, what goes in it, and — once
/// somebody has tried to save — what is missing, said under the part it is
/// about (`FE-10`).
class FormSection extends StatelessWidget {
  const FormSection({
    required this.label,
    required this.child,
    this.errorText,
    super.key,
  });

  final String label;
  final Widget child;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final error = errorText;
    return Padding(
      padding: const EdgeInsets.only(bottom: NestSpace.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: nest.text.label.copyWith(color: nest.colors.inkSecondary),
          ),
          const SizedBox(height: NestSpace.sm),
          child,
          if (error != null) ...[
            const SizedBox(height: NestSpace.xs),
            Text(
              error,
              style: nest.text.caption.copyWith(color: nest.colors.danger),
            ),
          ],
        ],
      ),
    );
  }
}
