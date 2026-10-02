import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/home_care_route.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/flags/feature_flag.dart';
import '../../../shared/flags/feature_flags_controller.dart';
import '../state/helper_language_controller.dart';
import '../state/home_care_controller.dart';

/// The ways into home care's V2 parts, above the jobs (home-care ADR-0004 to
/// ADR-0006): a big card for a helper's rooms today, and a chip each for the
/// routines, the stock and the languages — each only while its switch is on
/// (foundation ADR-0014).
class HomeCareShortcuts extends StatelessWidget {
  const HomeCareShortcuts({super.key});

  @override
  Widget build(BuildContext context) {
    final flags = context.watch<FeatureFlagsController>();
    final home = context.watch<HomeCareController>();
    final language = context.watch<HelperLanguageController>();
    final householdId = home.householdId;
    final canManage = home.access.canManage;
    final hasRoutines = flags.isOn(FeatureFlag.homeCareRoutines);
    final hasStock = flags.isOn(FeatureFlag.homeCareStock);
    final hasLanguage = language.isAvailable;
    if (!hasRoutines && !hasStock && !hasLanguage) {
      return const SizedBox.shrink();
    }
    void open(String path) => context.push(path);
    return Padding(
      padding: const EdgeInsets.only(bottom: NestSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasRoutines && !canManage) ...[
            _TodayCard(
              onTap: () => open(HomeCareRoute.todayPathFor(householdId)),
            ),
            const SizedBox(height: NestSpace.md),
          ],
          Wrap(
            spacing: NestSpace.sm,
            runSpacing: NestSpace.sm,
            children: [
              if (hasRoutines && canManage)
                NestChip(
                  label: HomeCareRoutineCopy.routines,
                  icon: LucideIcons.calendarSync,
                  onTap: () => open(HomeCareRoute.routinesPathFor(householdId)),
                ),
              if (hasStock)
                NestChip(
                  label: HomeCareStockCopy.stock,
                  icon: LucideIcons.clipboardList,
                  onTap: () => open(HomeCareRoute.stockPathFor(householdId)),
                ),
              if (hasLanguage)
                NestChip(
                  label: canManage
                      ? HomeCareLanguageCopy.languages
                      : language.language.ownName,
                  icon: LucideIcons.languages,
                  onTap: () =>
                      open(HomeCareRoute.languagesPathFor(householdId)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A helper's way to today's rooms: big, first, and one tap.
class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return NestCard(
      variant: NestCardVariant.tinted,
      onTap: onTap,
      child: Row(
        children: [
          const NestIconTile(
            icon: LucideIcons.doorOpen,
            tint: NestTileTint.basil,
          ),
          const SizedBox(width: NestSpace.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(HomeCareRoutineCopy.today, style: nest.text.title),
                Text(
                  HomeCareRoutineCopy.todayBanner,
                  style: nest.text.bodySecondary,
                ),
              ],
            ),
          ),
          Icon(LucideIcons.chevronRight, color: nest.colors.inkSecondary),
        ],
      ),
    );
  }
}
