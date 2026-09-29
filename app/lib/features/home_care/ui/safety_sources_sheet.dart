import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/safety/safety_source.dart';

/// Where the safety advice comes from — every source, named, and what it
/// says (home-care ADR-0002). A summary of theirs, not advice of ours, and
/// the sheet says so first.
Future<void> showSafetySources(BuildContext context) => showNestSheet<void>(
  context: context,
  title: HomeCareSafetyCopy.sourcesTitle,
  builder: (context) => const _SourcesBody(),
);

class _SourcesBody extends StatelessWidget {
  const _SourcesBody();

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return ListView(
      shrinkWrap: true,
      children: [
        Text(HomeCareSafetyCopy.sourcesIntro, style: nest.text.bodySecondary),
        const SizedBox(height: NestSpace.lg),
        for (final source in SafetySource.values) ...[
          NestToneRow(
            icon: Icons.menu_book_outlined,
            title: HomeCareSafetyCopy.sourceName(source),
            subtitle: HomeCareSafetyCopy.sourceSays(source),
          ),
          const SizedBox(height: NestSpace.sm),
        ],
        const SizedBox(height: NestSpace.lg),
      ],
    );
  }
}
