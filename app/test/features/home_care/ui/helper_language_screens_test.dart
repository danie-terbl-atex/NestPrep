import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nestprep/app/home_care_route.dart';
import 'package:nestprep/features/home_care/data/read_aloud.dart';
import 'package:nestprep/features/home_care/model/job_status.dart';
import 'package:nestprep/features/home_care/model/language/helper_language.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/home_care_fixtures.dart';
import '../../../support/home_care_routine_fixtures.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/pump_home_care.dart';

/// The helper's language through the real routes (home-care ADR-0006):
/// choosing one, her job's steps and safety in it — the safety always with
/// its English — read aloud, and English with a reason when it cannot be.
void main() {
  late HomeCareHarness harness;
  final languagesPath = HomeCareRoute.languagesPathFor(Fixtures.householdId);
  final stepsPath = HomeCareRoute.stepsPathFor(Fixtures.householdId, 'oven');
  final todayPath = HomeCareRoute.todayPathFor(Fixtures.householdId);

  setUp(() => harness = HomeCareHarness());
  tearDown(() => harness.close());

  Future<void> open(
    WidgetTester tester,
    String location, {
    bool asHelper = true,
  }) async {
    HomeCareHarness.makeRoom(tester);
    harness.photos.stored['oven/before'] = HomeCareFixtures.photoBytes;
    await harness.pump(
      tester,
      location: location,
      view: asHelper ? HomeCareFixtures.helperView() : null,
    );
  }

  group('the languages screen', () {
    testWidgets('a helper chooses her own, and hears a line of it', (
      tester,
    ) async {
      await open(tester, languagesPath);
      await harness.feedShell(tester);
      await harness.emitLanguages(tester, const {});
      expect(find.text(HomeCareLanguageCopy.myLanguage), findsOneWidget);
      expect(find.text(HomeCareLanguageCopy.notChosen), findsOneWidget);

      await tester.tap(find.text(HomeCareLanguageCopy.notChosen));
      await tester.pumpAndSettle();
      expect(find.text(HomeCareLanguageCopy.chooseLanguage), findsOneWidget);
      await tester.tap(find.text('isiZulu'));
      await tester.pumpAndSettle();
      expect(harness.profiles.methods, ['setLanguage']);
      expect(harness.profiles.writes.single.$2, {
        'memberId': Fixtures.thandiMemberId,
        'language': HelperLanguage.isiZulu,
        'by': Fixtures.thandiMemberId,
      });

      await harness.emitLanguages(tester, {
        Fixtures.thandiMemberId: HelperLanguage.isiZulu,
      });
      expect(
        find.text('[zu] ${HomeCareLanguageCopy.sampleLine}'),
        findsOneWidget,
      );
      expect(find.text(HomeCareLanguageCopy.machineTranslated), findsOneWidget);
      await tester.tap(
        find.bySemanticsLabel(
          HomeCareLanguageCopy.readAloudFor(
            '[zu] ${HomeCareLanguageCopy.sampleLine}',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(harness.voice.spoken.single, (
        '[zu] ${HomeCareLanguageCopy.sampleLine}',
        HelperLanguage.isiZulu,
      ));
    });

    testWidgets('a parent sees every helper’s and sets one for her', (
      tester,
    ) async {
      await open(tester, languagesPath, asHelper: false);
      await harness.feedShell(tester);
      await harness.emitLanguages(tester, {
        Fixtures.thandiMemberId: HelperLanguage.sepedi,
      });
      expect(find.text(HomeCareLanguageCopy.languages), findsOneWidget);
      expect(find.text('Thandi Helper'), findsOneWidget);
      expect(find.text('Sepedi · Northern Sotho'), findsOneWidget);

      await tester.tap(find.text('Thandi Helper'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xitsonga'));
      await tester.pumpAndSettle();
      expect(harness.profiles.writes.single.$2['memberId'], 'm-thandi');
      expect(
        harness.profiles.writes.single.$2['language'],
        HelperLanguage.xitsonga,
      );
    });

    testWidgets('holds its layout while the languages load', (tester) async {
      await open(tester, languagesPath);
      await harness.feedShell(tester);
      await tester.pump();
      expect(find.text(HomeCareLanguageCopy.notChosen), findsNothing);
    });

    testWidgets('languages that cannot be read say so, with a retry', (
      tester,
    ) async {
      await open(tester, languagesPath);
      await harness.feedShell(tester);
      harness.profiles.failProfilesWith(const UnavailableFailure());
      await tester.pumpAndSettle();
      expect(
        find.text(AppCopy.failure(const UnavailableFailure())),
        findsOneWidget,
      );
      await tester.tap(find.text(AppCopy.retry));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      expect(harness.profiles.profileAskedFor, hasLength(2));
    });

    testWidgets('says plainly when the switch is off', (tester) async {
      await open(tester, languagesPath);
      await harness.feedShell(tester);
      harness.flags.emit({'homeCareHelperLanguage': false});
      await tester.pumpAndSettle();
      expect(find.text(HomeCareCopy.switchedOffTitle), findsOneWidget);
    });
  });

  group('her job in her language', () {
    Future<void> openStepsInZulu(WidgetTester tester) async {
      await open(tester, stepsPath);
      await harness.emit(
        tester,
        jobList: [
          HomeCareFixtures.job(
            status: JobStatus.inProgress,
            productIds: const ['jik', 'windolene'],
          ),
        ],
      );
      await harness.emitLanguages(tester, {
        Fixtures.thandiMemberId: HelperLanguage.isiZulu,
      });
    }

    testWidgets('the steps are hers to read and hear, the English on request', (
      tester,
    ) async {
      await openStepsInZulu(tester);
      expect(
        find.text(HomeCareLanguageCopy.showing(HelperLanguage.isiZulu)),
        findsOneWidget,
      );
      expect(find.text('[zu] Open a window'), findsOneWidget);
      expect(find.text('Open a window'), findsNothing);

      await tester.tap(find.text(HomeCareLanguageCopy.showEnglish));
      await tester.pumpAndSettle();
      expect(find.text('Open a window'), findsOneWidget);

      await tester.tap(
        find.bySemanticsLabel(
          HomeCareLanguageCopy.readAloudFor('[zu] Open a window'),
        ),
      );
      await tester.pumpAndSettle();
      expect(harness.voice.spoken.last.$2, HelperLanguage.isiZulu);

      // Ticking a translated step still ticks the step.
      await tester.tap(find.text('[zu] Wipe clean'));
      await tester.pumpAndSettle();
      expect(harness.jobs.methods, contains('setDoneSteps'));
    });

    testWidgets('the safety is translated, badged, and never without its '
        'English', (tester) async {
      await open(tester, stepsPath);
      await harness.emit(
        tester,
        jobList: [
          HomeCareFixtures.job(productIds: const ['jik', 'windolene']),
        ],
      );
      await harness.emitLanguages(tester, {
        Fixtures.thandiMemberId: HelperLanguage.isiZulu,
      });
      final never = HomeCareSafetyCopy.neverTogether('Jik', 'Window spray');
      expect(find.text('[zu] $never'), findsOneWidget);
      expect(
        find.textContaining(HomeCareLanguageCopy.inEnglish(never)),
        findsOneWidget,
      );
      expect(find.text(HomeCareLanguageCopy.machineTranslated), findsWidgets);
      expect(
        find.text(HomeCareLanguageCopy.safetyStaysInEnglish),
        findsOneWidget,
      );
    });

    testWidgets('a phone with no voice for it reads the English, and says so', (
      tester,
    ) async {
      harness.voice.support = VoiceSupport.englishOnly;
      await openStepsInZulu(tester);
      expect(
        find.text(
          HomeCareLanguageCopy.voice(
            VoiceSupport.englishOnly,
            HelperLanguage.isiZulu,
          ),
        ),
        findsOneWidget,
      );
      await tester.tap(
        find.bySemanticsLabel(
          HomeCareLanguageCopy.readAloudFor('[zu] Open a window'),
        ),
      );
      await tester.pumpAndSettle();
      expect(harness.voice.spoken.last, (
        'Open a window',
        HelperLanguage.english,
      ));
    });

    testWidgets('a phone that cannot speak shows no button, and says why', (
      tester,
    ) async {
      harness.voice.support = VoiceSupport.none;
      await openStepsInZulu(tester);
      expect(find.byIcon(LucideIcons.volume2), findsNothing);
      expect(
        find.text(
          HomeCareLanguageCopy.voice(VoiceSupport.none, HelperLanguage.isiZulu),
        ),
        findsOneWidget,
      );
    });

    testWidgets('a translation that cannot happen leaves English, with why', (
      tester,
    ) async {
      harness.translations.failTranslateWith = const HomeCareFailure(
        HomeCareProblem.translationLimitReached,
      );
      await openStepsInZulu(tester);
      expect(find.text('Open a window'), findsOneWidget);
      expect(
        find.text(
          HomeCareCopy.problem(HomeCareProblem.translationLimitReached),
        ),
        findsOneWidget,
      );

      harness.translations.failTranslateWith = null;
      await tester.tap(find.text(AppCopy.retry));
      await tester.pumpAndSettle();
      expect(find.text('[zu] Open a window'), findsOneWidget);
    });

    testWidgets('a routine’s items are in her language too', (tester) async {
      await open(tester, todayPath);
      await harness.feedShell(tester);
      await harness.emitRoutines(
        tester,
        routineList: [RoutineFixtures.everyDay()],
      );
      await harness.emitLanguages(tester, {
        Fixtures.thandiMemberId: HelperLanguage.chiShona,
      });
      expect(find.text('[sn] Wipe the counters'), findsOneWidget);
    });

    testWidgets('while switched off she reads English, and nothing is asked', (
      tester,
    ) async {
      harness.flagsDefaultOn = false;
      await openStepsInZulu(tester);
      expect(find.text('Open a window'), findsOneWidget);
      expect(harness.translations.asked, isEmpty);
      expect(harness.profiles.profileAskedFor, isEmpty);
    });
  });
}
