import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../features/home_care/data/cleaning_job_repository.dart';
import '../features/home_care/data/helper_profile_repository.dart';
import '../features/home_care/data/home_care_library_repository.dart';
import '../features/home_care/data/read_aloud.dart';
import '../features/home_care/data/translation_repository.dart';
import '../features/home_care/state/helper_language_controller.dart';
import '../features/home_care/state/home_care_controller.dart';
import '../features/home_care/state/read_aloud_controller.dart';
import '../features/household/model/household_view.dart';
import '../shared/flags/feature_flag.dart';
import '../shared/flags/feature_flags_controller.dart';
import 'household_route.dart';

/// What every home-care screen shares (home-care ADR-0001, ADR-0006): the
/// jobs, rooms and products; the viewer's language and the lines translated
/// into it; and the phone's voice. Each follows the one before it, so a
/// changed grant or a flipped switch reaches every screen at once.
Widget homeCareScope(BuildContext context, GoRouterState state, Widget child) {
  final householdId = HouseholdRoute.idFrom(state);
  return MultiProvider(
    providers: [
      ChangeNotifierProxyProvider<HouseholdView, HomeCareController>(
        create: (context) => HomeCareController(
          jobRepository: context.read<CleaningJobRepository>(),
          libraryRepository: context.read<HomeCareLibraryRepository>(),
          householdId: householdId,
          household: context.read<HouseholdView>(),
        ),
        update: (context, view, controller) =>
            controller!..followHousehold(view),
      ),
      ChangeNotifierProxyProvider2<
        HomeCareController,
        FeatureFlagsController,
        HelperLanguageController
      >(
        create: (context) => HelperLanguageController(
          profileRepository: context.read<HelperProfileRepository>(),
          translationRepository: context.read<TranslationRepository>(),
          householdId: householdId,
        ),
        update: (context, home, flags, controller) => controller!
          ..follow(
            home.access,
            isOn: flags.isOn(FeatureFlag.homeCareHelperLanguage),
          ),
      ),
      ChangeNotifierProxyProvider<
        HelperLanguageController,
        ReadAloudController
      >(
        create: (context) =>
            ReadAloudController(readAloud: context.read<ReadAloud>()),
        update: (context, language, controller) =>
            controller!..follow(language.language),
      ),
    ],
    child: child,
  );
}
