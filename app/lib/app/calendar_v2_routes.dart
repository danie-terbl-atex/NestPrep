import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../features/calendar/data/calendar_repository.dart';
import '../features/groceries/data/grocery_repository.dart';
import '../features/household/model/household_view.dart';
import '../features/mental_load/data/card_image_sharer.dart';
import '../features/mental_load/state/load_listeners.dart';
import '../features/mental_load/state/mental_load_controller.dart';
import '../features/mental_load/ui/mental_load_screen.dart';
import '../features/nanny_hub/data/shift_repository.dart';
import '../features/nanny_hub/model/nanny_access.dart';
import '../features/school_letter/data/letter_picker.dart';
import '../features/school_letter/data/school_letter_reader.dart';
import '../features/school_letter/state/school_letter_controller.dart';
import '../features/school_letter/ui/school_letter_screen.dart';
import '../features/todos/data/todo_repository.dart';
import '../shared/time/household_clock.dart';
import 'calendar_v2_route.dart';
import 'household_route.dart';
import 'viewer_member.dart';

/// Snap a school letter and the shared week (calendar ADR-0005, ADR-0006).
/// Each screen's way in is hidden when its flag is off; the routes stay, so a
/// switched-off capability is unreachable rather than broken, and the server
/// refuses the letter's callable on the same flag.
List<GoRoute> calendarV2Routes() => [
  GoRoute(
    path: CalendarV2Route.letterPath,
    builder: (context, state) => ChangeNotifierProvider(
      create: (context) => SchoolLetterController(
        schoolLetterReader: context.read<SchoolLetterReader>(),
        letterPicker: context.read<LetterPicker>(),
        calendarRepository: context.read<CalendarRepository>(),
        householdId: HouseholdRoute.idFrom(state),
        memberId: viewerMemberIdOf(context),
      ),
      child: const SchoolLetterScreen(),
    ),
  ),
  GoRoute(
    path: CalendarV2Route.sharedWeekPath,
    builder: (context, state) =>
        ChangeNotifierProxyProvider<HouseholdView, MentalLoadController>(
          create: (context) => MentalLoadController(
            loadListeners: LoadListeners(
              calendarRepository: context.read<CalendarRepository>(),
              todoRepository: context.read<TodoRepository>(),
              groceryRepository: context.read<GroceryRepository>(),
              shiftRepository: context.read<ShiftRepository>(),
              householdId: HouseholdRoute.idFrom(state),
              includeCare: NannyAccess.of(context.read<HouseholdView>())
                  .canView,
            ),
            cardImageSharer: context.read<CardImageSharer>(),
            householdClock: context.read<HouseholdClock>(),
            householdMembers: context.read<HouseholdView>().members,
          ),
          update: (context, view, controller) =>
              controller!..showMembers(view.members),
          child: const MentalLoadScreen(),
        ),
  ),
];
