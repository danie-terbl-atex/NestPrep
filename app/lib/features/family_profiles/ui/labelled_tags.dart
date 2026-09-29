import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';

/// A small label and the tags under it — "Likes", then what they like. The
/// label is the signal; the tags' tone only repeats it (`FE-13`).
class LabelledTags extends StatelessWidget {
  const LabelledTags({required this.label, required this.tags, super.key});

  final String label;
  final List<Widget> tags;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: NestSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: nest.text.label.copyWith(color: nest.colors.inkSecondary),
          ),
          const SizedBox(height: NestSpace.sm),
          Wrap(spacing: NestSpace.sm, runSpacing: NestSpace.sm, children: tags),
        ],
      ),
    );
  }
}
