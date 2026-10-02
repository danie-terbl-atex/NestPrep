import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/flags/feature_flag.dart';
import '../../../shared/flags/feature_flags_controller.dart';
import '../../../shared/time/household_clock.dart';
import '../model/offline_status.dart';
import '../state/offline_keeper.dart';
import 'hub_clock.dart';

/// One line on the emergency sheet and every child card saying whether this
/// phone can show it without a signal, and when it was last brought up to
/// date (nanny-hub ADR-0007). Calm when saved; a quiet warning when it is
/// not, and then the whole line is the way to try again.
class OfflineBadge extends StatelessWidget {
  const OfflineBadge({super.key});

  @override
  Widget build(BuildContext context) {
    if (!context.watch<FeatureFlagsController>().isOn(
      FeatureFlag.nannyOffline,
    )) {
      return const SizedBox.shrink();
    }
    final keeper = context.watch<OfflineKeeper>();
    final clock = context.read<HouseholdClock>();
    String when(DateTime at) => clock.dateOf(at) == clock.today
        ? clock.timeOf(at)
        : NannyOfflineCopy.syncedOn(clock.dayOf(at), clock.timeOf(at));
    final (icon, tone, title, detail, retries) = switch (keeper.status) {
      SavedOffline(:final savedAt) => (
        LucideIcons.cloudCheck,
        NestTagTone.success,
        NannyOfflineCopy.saved,
        NannyOfflineCopy.lastSynced(when(savedAt)),
        false,
      ),
      SavingOffline(:final savedAt) => (
        LucideIcons.cloudSync,
        NestTagTone.accent,
        NannyOfflineCopy.saving,
        savedAt == null ? null : NannyOfflineCopy.lastSynced(when(savedAt)),
        false,
      ),
      NotSavedOffline() => (
        LucideIcons.cloudDownload,
        NestTagTone.accent,
        NannyOfflineCopy.notSaved,
        NannyOfflineCopy.notSavedBody,
        true,
      ),
      OfflineSaveFailed(:final savedAt, :final isNoSignal) => (
        LucideIcons.cloudOff,
        NestTagTone.warning,
        isNoSignal
            ? NannyOfflineCopy.noSignal
            : savedAt == null
            ? NannyOfflineCopy.failed
            : NannyOfflineCopy.failedKeeping,
        savedAt != null
            ? NannyOfflineCopy.showingSaved(when(savedAt))
            : isNoSignal
            ? NannyOfflineCopy.nothingSaved
            : NannyOfflineCopy.tapToRetry,
        true,
      ),
    };
    return NestToneRow(
      icon: icon,
      tone: tone,
      title: title,
      subtitle: detail,
      onTap: retries ? keeper.saveNow : null,
    );
  }
}
