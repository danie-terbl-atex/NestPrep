import 'package:flutter/widgets.dart';

import '../tokens/nest_spacing.dart';
import '../tokens/nest_theme.dart';
import 'nest_eyebrow.dart';

/// The opening of a way-in screen (design-system ADR-0008): a short eyebrow,
/// one warm Fraunces line read as the heading, and a sentence under it.
class NestIntro extends StatelessWidget {
  const NestIntro({
    required this.title,
    this.eyebrow,
    this.body,
    this.isLarge = true,
    super.key,
  });

  final String title;
  final String? eyebrow;
  final String? body;
  final bool isLarge;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final eyebrowText = eyebrow;
    final bodyText = body;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (eyebrowText != null) ...[
          NestEyebrow(eyebrowText),
          const SizedBox(height: NestSpace.sm),
        ],
        Semantics(
          header: true,
          child: Text(
            title,
            style: isLarge ? nest.text.display : nest.text.headline,
          ),
        ),
        if (bodyText != null) ...[
          const SizedBox(height: NestSpace.md),
          Text(bodyText, style: nest.text.bodySecondary),
        ],
      ],
    );
  }
}
