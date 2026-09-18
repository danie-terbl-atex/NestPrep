import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/failure/app_failure.dart';
import '../data/household_repository.dart';
import '../model/household.dart';

/// Choosing which household to look at.
///
/// One account may belong to several (household ADR-0002) and the account
/// document has always carried the list — but until this existed nothing could
/// move between them, so the second household an account joined was the only
/// one it could ever see.
///
/// The names are read once, on opening: nobody is watching the list of
/// households they belong to while they read it, and the ids come from the
/// account, which is live.
Future<String?> showSwitchHouseholdSheet({
  required BuildContext context,
  required List<String> householdIds,
  required String? activeHouseholdId,
}) {
  final repository = context.read<HouseholdRepository>();
  return showNestSheet<String>(
    context: context,
    title: AppCopy.householdSwitch,
    builder: (sheetContext) => _SwitchBody(
      households: repository.readHouseholds(householdIds),
      activeHouseholdId: activeHouseholdId,
    ),
  );
}

class _SwitchBody extends StatelessWidget {
  const _SwitchBody({
    required this.households,
    required this.activeHouseholdId,
  });

  final Future<List<Household>> households;
  final String? activeHouseholdId;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Household>>(
      future: households,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          final error = snapshot.error;
          return NestBanner(
            message: AppCopy.failure(
              error is AppFailure ? error : UnknownFailure(error!),
            ),
            tone: NestBannerTone.danger,
          );
        }
        final found = snapshot.data;
        if (found == null) {
          return const NestLoadingView(rows: 2);
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final household in found)
              Padding(
                padding: const EdgeInsets.only(bottom: NestSpace.xs),
                child: NestListRow(
                  key: ValueKey(household.id),
                  title: household.name,
                  isSelected: household.id == activeHouseholdId,
                  onTap: household.id == activeHouseholdId
                      ? null
                      : () => Navigator.of(context).pop(household.id),
                ),
              ),
          ],
        );
      },
    );
  }
}
