import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/family_route.dart';
import '../../../app/household_shell.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../../accounts/ui/account_menu_button.dart';
import '../../family_profiles/model/family_access.dart';
import '../../household/model/household_area.dart';
import '../../household/model/household_view.dart';
import '../../notifications/ui/notification_bell.dart';
import '../model/lunch_board.dart';
import '../state/lunch_board_controller.dart';
import 'lunch_board_body.dart';
import 'lunch_week_bar.dart';

/// The household's home: each child's school lunches for the week
/// (lunch-box ADR-0001, ADR-0004). One controller joins the children, the
/// library, the plans and the go-to boxes, so this screen has one loading
/// state and reads offline from cached documents.
class LunchScreen extends StatelessWidget {
  const LunchScreen({required this.onSelectTab, super.key});

  final ValueChanged<HouseholdTab> onSelectTab;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LunchBoardController>();
    final view = context.watch<HouseholdView>();
    final failure = controller.actionFailure;
    // Somebody who may only look sees the week, and none of the controls
    // that change it (household ADR-0003).
    final canEdit = view.permissions.canEdit(HouseholdArea.lunch);
    final board = controller.board;
    final isThisWeek = switch (board) {
      AsyncData(:final value) => value.isThisWeek,
      _ => true,
    };

    return NestScaffold(
      title: LunchCopy.title,
      subtitle: LunchCopy.weekOf(
        NestDates.schoolWeekRange(controller.week.monday),
      ),
      trailing: const [NotificationBell(), AccountMenuButton()],
      bottomBar: HouseholdTabBar(
        current: HouseholdTab.lunch,
        onSelect: onSelectTab,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (failure != null)
            Padding(
              padding: const EdgeInsets.only(bottom: NestSpace.md),
              child: NestBanner(
                message: AppCopy.failure(failure),
                tone: NestBannerTone.danger,
                actionLabel: AppCopy.back,
                onAction: controller.dismissActionFailure,
              ),
            ),
          LunchWeekBar(
            week: controller.week,
            isThisWeek: isThisWeek,
            onPrevious: controller.goToPreviousWeek,
            onNext: controller.goToNextWeek,
            onThisWeek: controller.goToThisWeek,
            planningWeek: controller.planningWeek,
          ),
          const SizedBox(height: NestSpace.md),
          Expanded(
            child: NestAsyncView<LunchBoard>(
              state: board,
              isEmpty: (value) => !value.hasChildren,
              onRetry: controller.retry,
              emptyBuilder: (context) => _NoChildren(view: view),
              dataBuilder: (context, value) =>
                  LunchBoardBody(board: value, canEdit: canEdit),
            ),
          ),
        ],
      ),
    );
  }
}

/// Nobody to pack for yet. The way in is in family profiles, where a child
/// is marked and their allergies are kept — so that is the one button.
class _NoChildren extends StatelessWidget {
  const _NoChildren({required this.view});

  final HouseholdView view;

  @override
  Widget build(BuildContext context) {
    final access = FamilyAccess.of(view);
    if (!access.seesEveryProfile) {
      return const NestEmptyView(
        icon: LucideIcons.lock,
        title: LunchCopy.noChildrenTitle,
        message: LunchCopy.cannotSeeChildren,
      );
    }
    return NestEmptyView(
      icon: LucideIcons.sandwich,
      title: LunchCopy.noChildrenTitle,
      message: LunchCopy.noChildrenBody,
      actionLabel: LunchCopy.openFamily,
      onAction: () => context.push(FamilyRoute.pathFor(view.household.id)),
    );
  }
}
