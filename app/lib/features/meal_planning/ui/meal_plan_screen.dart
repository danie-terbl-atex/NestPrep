import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/household_shell.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../../accounts/ui/account_menu_button.dart';
import '../../household/model/household_area.dart';
import '../../household/model/household_view.dart';
import '../../household/ui/household_link_button.dart';
import '../../notifications/ui/notification_bell.dart';
import '../model/meal_week.dart';
import '../state/meal_plan_controller.dart';
import 'meal_library_sheet.dart';
import 'planned_day_card.dart';

/// The week's breakfast, lunch and dinner (meal-planning ADR-0001). One
/// document is the whole week, so this screen is one listener and reads offline
/// from a single cached document.
class MealPlanScreen extends StatelessWidget {
  const MealPlanScreen({required this.onSelectTab, super.key});

  final ValueChanged<HouseholdTab> onSelectTab;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<MealPlanController>();
    final failure = controller.actionFailure;
    // A plan somebody may only read: no library, no copying, no picking
    // (household ADR-0003).
    final canEdit = context.watch<HouseholdView>().permissions.canEdit(
      HouseholdArea.meals,
    );

    return NestScaffold(
      title: AppCopy.mealsTitle,
      subtitle: NestDates.weekRange(controller.weekStart),
      trailing: [
        if (canEdit)
          NestIconButton(
            icon: Icons.menu_book_outlined,
            label: AppCopy.mealsManage,
            onPressed: () => showMealLibrarySheet(context: context),
          ),
        const NotificationBell(),
        const HouseholdLinkButton(),
        const AccountMenuButton(),
      ],
      bottomBar: HouseholdTabBar(
        current: HouseholdTab.meals,
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
          Row(
            children: [
              NestIconButton(
                icon: Icons.chevron_left,
                label: AppCopy.calendarPreviousWeek,
                variant: NestIconButtonVariant.plain,
                onPressed: controller.goToPreviousWeek,
              ),
              Expanded(
                child: NestButton(
                  label: AppCopy.mealsCopyLastWeek,
                  icon: Icons.copy_all_outlined,
                  variant: NestButtonVariant.tonal,
                  size: NestButtonSize.small,
                  isLoading: controller.isCopying,
                  onPressed: canEdit ? controller.copyLastWeek : null,
                ),
              ),
              NestIconButton(
                icon: Icons.chevron_right,
                label: AppCopy.calendarNextWeek,
                variant: NestIconButtonVariant.plain,
                onPressed: controller.goToNextWeek,
              ),
            ],
          ),
          const SizedBox(height: NestSpace.lg),
          Expanded(
            child: NestAsyncView<MealWeek>(
              state: controller.week,
              // The grid is the empty state: twenty-one slots that each say
              // they are empty and each open the picker. Replacing it with a
              // blank view would take away the only way to plan the first meal
              // (`FE-08`).
              isEmpty: (_) => false,
              onRetry: controller.retry,
              emptyBuilder: (_) => const SizedBox.shrink(),
              dataBuilder: (_, week) => ListView(
                padding: const EdgeInsets.only(
                  bottom: NestSize.bottomBarHeight * 2,
                ),
                children: [
                  if (week.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(bottom: NestSpace.md),
                      child: NestBanner(message: AppCopy.mealsEmptyBody),
                    ),
                  for (final day in week.days)
                    Padding(
                      padding: const EdgeInsets.only(bottom: NestSpace.md),
                      child: PlannedDayCard(
                        key: ValueKey(day.date.iso),
                        day: day,
                        today: week.today,
                        library: week.library,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
