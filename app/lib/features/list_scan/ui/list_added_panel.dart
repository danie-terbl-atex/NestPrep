import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';

/// The lines are on the grocery list: how many, and the two ways on. They
/// came from a list the AI read, so Twig celebrates (design-system ADR-0012).
class ListAddedPanel extends StatelessWidget {
  const ListAddedPanel({
    required this.added,
    required this.onBackToList,
    required this.onSnapAnother,
    super.key,
  });

  final int added;
  final VoidCallback onBackToList;
  final VoidCallback onSnapAnother;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: NestSpace.xxl),
        child: NestRiseIn(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(
                child: NestTwig(
                  pose: NestTwigPose.celebrate,
                  size: NestSize.twigLarge,
                ),
              ),
              const SizedBox(height: NestSpace.lg),
              Semantics(
                liveRegion: true,
                child: Text(
                  ListScanCopy.addedTitle(added),
                  style: nest.text.title.copyWith(color: nest.colors.ink),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: NestSpace.sm),
              Text(
                ListScanCopy.addedBody,
                style: nest.text.bodySecondary,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: NestSpace.xxl),
              NestButton(
                key: const ValueKey('list-scan-back'),
                label: ListScanCopy.backToList,
                icon: LucideIcons.shoppingCart,
                onPressed: onBackToList,
              ),
              const SizedBox(height: NestSpace.sm),
              NestButton(
                label: ListScanCopy.snapAnother,
                variant: NestButtonVariant.ghost,
                onPressed: onSnapAnother,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
