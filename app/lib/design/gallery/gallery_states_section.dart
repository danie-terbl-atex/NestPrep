import 'package:flutter/material.dart';

import '../../features/observability/crash_reporting.dart';
import '../../shared/async/async_state.dart';
import '../../shared/failure/app_failure.dart';
import '../nest_kit.dart';
import 'gallery_group.dart';

class GalleryStatesSection extends StatelessWidget {
  const GalleryStatesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const GalleryGroup(
          title: 'Crash reporting',
          children: [
            NestBanner(
              message:
                  'A debug or emulator build sends nothing to Crashlytics '
                  '(observability ADR-0001).',
            ),
            NestButton(
              label: 'Force a crash',
              icon: Icons.bug_report_outlined,
              variant: NestButtonVariant.danger,
              onPressed: CrashReporting.forceACrashForTesting,
            ),
          ],
        ),
        const GalleryGroup(
          title: 'Banners',
          children: [
            NestBanner(message: 'You are offline; changes will sync later.'),
            NestBanner(message: 'Saved.', tone: NestBannerTone.success),
            NestBanner(
              message: 'This routine has no assignee.',
              tone: NestBannerTone.warning,
            ),
            NestBanner(
              message: 'Could not send. Check your connection.',
              tone: NestBannerTone.danger,
              actionLabel: 'Retry',
            ),
          ],
        ),
        const GalleryGroup(
          title: 'Tags and tone rows',
          children: [
            Wrap(
              spacing: NestSpace.sm,
              runSpacing: NestSpace.sm,
              children: [
                NestTag(label: 'Neutral'),
                NestTag(label: 'Accent', tone: NestTagTone.accent),
                NestTag(label: 'Success', tone: NestTagTone.success),
                NestTag(
                  label: 'Nut-free',
                  tone: NestTagTone.warning,
                  icon: Icons.no_food_outlined,
                ),
                NestTag(
                  label: 'Severe',
                  tone: NestTagTone.danger,
                  icon: Icons.emergency_outlined,
                ),
              ],
            ),
            NestToneRow(
              icon: Icons.emergency_outlined,
              tone: NestTagTone.danger,
              title: 'Peanuts',
              subtitle: 'Adrenaline pen in the school bag',
              trailing: NestTag(label: 'Severe', tone: NestTagTone.danger),
            ),
            NestToneRow(
              icon: Icons.warning_amber_rounded,
              tone: NestTagTone.warning,
              title: 'Kiwi',
              trailing: NestTag(label: 'Moderate', tone: NestTagTone.warning),
            ),
          ],
        ),
        const GalleryGroup(
          title: 'Loading',
          children: [NestLoadingView(rows: 3)],
        ),
        GalleryGroup(
          title: 'Empty',
          children: [
            NestEmptyView(
              title: 'Nothing to buy',
              message: 'Add the first item and everyone will see it.',
              icon: Icons.shopping_basket_outlined,
              actionLabel: 'Add an item',
              onAction: () {},
            ),
          ],
        ),
        GalleryGroup(
          title: 'Error',
          children: [
            NestErrorView(
              message: 'NestPrep cannot reach the server right now.',
              retryLabel: 'Try again',
              onRetry: () {},
            ),
          ],
        ),
        GalleryGroup(
          title: 'Async view, data',
          children: [
            NestAsyncView<List<String>>(
              state: const AsyncData(['Milk', 'Bread']),
              isEmpty: (items) => items.isEmpty,
              onRetry: () {},
              emptyBuilder: (_) => const SizedBox.shrink(),
              dataBuilder: (context, items) => Column(
                children: [for (final item in items) NestListRow(title: item)],
              ),
            ),
            NestAsyncView<List<String>>(
              state: const AsyncFailure(UnavailableFailure()),
              isEmpty: (items) => items.isEmpty,
              onRetry: () {},
              emptyBuilder: (_) => const SizedBox.shrink(),
              dataBuilder: (_, _) => const SizedBox.shrink(),
            ),
          ],
        ),
      ],
    );
  }
}
