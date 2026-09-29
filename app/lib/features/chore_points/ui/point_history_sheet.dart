import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/copy/points_copy.dart';
import '../../household/model/member.dart';
import '../data/points_repository.dart';
import '../model/point_entry.dart';
import '../state/point_history_controller.dart';

/// Where one child's stars came from and went (todos ADR-0003): the latest
/// lines of the ledger the balance is the sum of. Its own controller lives as
/// long as the sheet.
Future<void> showPointHistorySheet({
  required BuildContext context,
  required String householdId,
  required Member child,
}) {
  final repository = context.read<PointsRepository>();
  return showNestSheet<void>(
    context: context,
    title: PointsCopy.historyTitle(child.displayName),
    builder: (_) => ChangeNotifierProvider(
      create: (_) => PointHistoryController(
        pointsRepository: repository,
        householdId: householdId,
        memberId: child.id,
      ),
      child: const _HistoryBody(),
    ),
  );
}

class _HistoryBody extends StatelessWidget {
  const _HistoryBody();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PointHistoryController>();
    return switch (controller.entries) {
      AsyncLoading() => const Padding(
        padding: EdgeInsets.symmetric(vertical: NestSpace.xl),
        child: NestSkeleton(height: NestSize.controlLarge),
      ),
      AsyncFailure(:final failure) => NestErrorView(
        message: AppCopy.failure(failure),
        retryLabel: AppCopy.retry,
        onRetry: controller.retry,
      ),
      AsyncData(:final value) when value.isEmpty => const Padding(
        padding: EdgeInsets.symmetric(vertical: NestSpace.xl),
        child: Text(PointsCopy.historyEmpty),
      ),
      AsyncData(:final value) => ListView(
        shrinkWrap: true,
        children: [for (final entry in value) _EntryRow(entry: entry)],
      ),
    };
  }
}

class _EntryRow extends StatelessWidget {
  const _EntryRow({required this.entry});

  final PointEntry entry;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final gained = entry.delta >= 0;
    return NestListRow(
      key: ValueKey(entry.id),
      title: entry.title,
      subtitle: PointsCopy.entryKind(entry.kind),
      trailing: Text(
        PointsCopy.delta(entry.delta),
        style: nest.text.bodyStrong.copyWith(
          color: gained ? nest.colors.success : nest.colors.inkSecondary,
        ),
      ),
    );
  }
}
