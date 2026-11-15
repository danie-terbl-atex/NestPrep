import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/copy/starter_copy.dart';
import '../../../shared/failure/app_failure.dart';
import '../../../shared/time/household_clock.dart';
import '../../household/model/household_view.dart';
import '../data/starter_content_repository.dart';
import '../model/starter_content.dart';

/// Says the screen is showing examples, and clears every one of them at once
/// (household ADR-0010). A screen passes the ids it is showing; the notice is
/// there only while one of them is an example, and only for an admin — the
/// one person the rules let remove what the household's maker wrote.
class StarterExamplesBanner extends StatefulWidget {
  const StarterExamplesBanner({required this.shownIds, super.key});

  final Iterable<String> shownIds;

  @override
  State<StarterExamplesBanner> createState() => _StarterExamplesBannerState();
}

class _StarterExamplesBannerState extends State<StarterExamplesBanner> {
  bool _isClearing = false;

  Future<void> _clear() async {
    final view = context.read<HouseholdView>();
    final repository = context.read<StarterContentRepository>();
    final clock = context.read<HouseholdClock>();
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showNestConfirm(
      context: context,
      title: StarterCopy.clearTitle,
      message: StarterCopy.clearMessage,
      confirmLabel: StarterCopy.clearConfirm,
      cancelLabel: StarterCopy.clearCancel,
      isDangerous: true,
    );
    if (confirmed != true || !mounted) return;
    setState(() => _isClearing = true);
    try {
      await repository.clear(householdId: view.household.id, clock: clock);
    } on AppFailure catch (failure) {
      messenger.showSnackBar(SnackBar(content: Text(AppCopy.failure(failure))));
    } finally {
      if (mounted) setState(() => _isClearing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.select<HouseholdView, bool>(
      (view) => view.viewerIsAdmin,
    );
    if (!isAdmin || !widget.shownIds.any(StarterContent.isExample)) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: NestSpace.md),
      child: NestBanner(
        message: StarterCopy.bannerMessage,
        actionLabel: StarterCopy.bannerAction,
        onAction: _isClearing ? null : _clear,
      ),
    );
  }
}
