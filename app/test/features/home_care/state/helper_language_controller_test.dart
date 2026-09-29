import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/home_care/data/read_aloud.dart';
import 'package:nestprep/features/home_care/model/home_care_access.dart';
import 'package:nestprep/features/home_care/model/language/helper_language.dart';
import 'package:nestprep/features/home_care/model/language/helper_profile.dart';
import 'package:nestprep/features/home_care/model/language/translated_line.dart';
import 'package:nestprep/features/home_care/state/helper_language_controller.dart';
import 'package:nestprep/features/home_care/state/read_aloud_controller.dart';
import 'package:nestprep/features/household/model/access_level.dart';
import 'package:nestprep/shared/async/async_state.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/fake_home_care_v2.dart';
import '../../../support/household_fixtures.dart';

/// The viewer's language and the lines translated into it (home-care
/// ADR-0006): English while switched off, her own profile for a helper,
/// the cache before the Function, and every line asked for once.
void main() {
  late FakeHelperProfileRepository profiles;
  late FakeTranslationRepository translations;

  const family = HomeCareAccess(
    level: AccessLevel.edit,
    viewerMemberId: Fixtures.samMemberId,
  );
  const cleaner = HomeCareAccess(
    level: AccessLevel.own,
    viewerMemberId: Fixtures.thandiMemberId,
  );

  HelperProfile zulu(String memberId) => HelperProfile(
    id: memberId,
    language: HelperLanguage.isiZulu,
    updatedBy: memberId,
  );

  HelperLanguageController controllerFor(
    HomeCareAccess access, {
    bool isOn = true,
  }) {
    final controller = HelperLanguageController(
      profileRepository: profiles,
      translationRepository: translations,
      householdId: Fixtures.householdId,
    )..follow(access, isOn: isOn);
    addTearDown(controller.dispose);
    return controller;
  }

  setUp(() {
    profiles = FakeHelperProfileRepository();
    translations = FakeTranslationRepository();
  });
  tearDown(() => profiles.close());

  group('which language', () {
    test('everything is English, and nothing is read, while switched off', () {
      final controller = controllerFor(cleaner, isOn: false);
      expect(controller.isAvailable, isFalse);
      expect(controller.language, HelperLanguage.english);
      expect(profiles.profileAskedFor, isEmpty);
      expect(profiles.allAskedFor, 0);
    });

    test(
      'a helper holding own reads her own profile, and nobody else’s',
      () async {
        final controller = controllerFor(cleaner);
        await pumpEventQueue();
        expect(profiles.profileAskedFor, [Fixtures.thandiMemberId]);
        expect(profiles.allAskedFor, 0);

        profiles.emitProfiles([zulu(Fixtures.thandiMemberId)]);
        await pumpEventQueue();
        expect(controller.language, HelperLanguage.isiZulu);
        expect(controller.profilesState, isA<AsyncData<void>>());
      },
    );

    test('family reads everybody’s, and reads in its own', () async {
      final controller = controllerFor(family);
      await pumpEventQueue();
      expect(profiles.allAskedFor, 1);

      profiles.emitProfiles([zulu(Fixtures.thandiMemberId)]);
      await pumpEventQueue();
      expect(
        controller.languageOf(Fixtures.thandiMemberId),
        HelperLanguage.isiZulu,
      );
      expect(controller.language, HelperLanguage.english);
    });

    test(
      'languages that cannot be read leave English standing, with why',
      () async {
        final controller = controllerFor(family);
        await pumpEventQueue();
        profiles.failProfilesWith(const PermissionDeniedFailure());
        await pumpEventQueue();
        expect(controller.profilesState, isA<AsyncFailure<void>>());
        expect(controller.language, HelperLanguage.english);

        await controller.retryProfiles();
        expect(profiles.allAskedFor, 2);
      },
    );

    test('setting one writes it in the viewer’s name', () async {
      final controller = controllerFor(family);
      await controller.setLanguage(
        Fixtures.thandiMemberId,
        HelperLanguage.sepedi,
      );
      expect(profiles.methods, ['setLanguage']);
      expect(profiles.writes.single.$2, {
        'memberId': Fixtures.thandiMemberId,
        'language': HelperLanguage.sepedi,
        'by': Fixtures.samMemberId,
      });
    });
  });

  group('translating', () {
    Future<HelperLanguageController> aZuluHelper() async {
      final controller = controllerFor(cleaner);
      await pumpEventQueue();
      profiles.emitProfiles([zulu(Fixtures.thandiMemberId)]);
      await pumpEventQueue();
      return controller;
    }

    test('English asks for nothing', () async {
      final controller = controllerFor(family);
      controller.ensure(['Open a window']);
      await pumpEventQueue();
      expect(translations.asked, isEmpty);
      expect(controller.lineFor('Open a window').isTranslated, isFalse);
    });

    test(
      'the cache answers first, and only what it lacks is paid for',
      () async {
        translations.cache['Open a window'] = 'Vula ifasitela';
        final controller = await aZuluHelper();
        controller.ensure(['Open a window', 'Wipe clean', 'Open a window']);
        await pumpEventQueue();

        expect(translations.asked, [
          ['Wipe clean'],
        ]);
        expect(controller.lineFor('Open a window').text, 'Vula ifasitela');
        expect(controller.lineFor('Wipe clean').text, '[zu] Wipe clean');
        expect(
          controller.lineFor('Wipe clean').source,
          TranslationSource.machine,
        );
      },
    );

    test('a line is asked for once, however often the screen builds', () async {
      final controller = await aZuluHelper();
      controller
        ..ensure(['Wipe clean'])
        ..ensure(['Wipe clean']);
      await pumpEventQueue();
      controller.ensure(['Wipe clean']);
      await pumpEventQueue();
      expect(translations.asked, hasLength(1));
    });

    test('more lines than one call carries go in batches it accepts', () async {
      final controller = await aZuluHelper();
      controller.ensure([for (var n = 0; n < 130; n++) 'Step $n']);
      await pumpEventQueue();
      expect(translations.asked.map((batch) => batch.length), [60, 60, 10]);
    });

    test('a failure shows English with why, and a retry asks again', () async {
      translations.failTranslateWith = const HomeCareFailure(
        HomeCareProblem.translationLimitReached,
      );
      final controller = await aZuluHelper();
      controller.ensure(['Wipe clean']);
      await pumpEventQueue();
      expect(controller.translationFailure, isA<HomeCareFailure>());
      expect(controller.lineFor('Wipe clean').text, 'Wipe clean');
      expect(controller.isTranslating, isFalse);

      translations.failTranslateWith = null;
      controller.retryTranslation(['Wipe clean']);
      await pumpEventQueue();
      expect(controller.translationFailure, isNull);
      expect(controller.lineFor('Wipe clean').text, '[zu] Wipe clean');
    });

    test('the English can be shown beside, and hidden again', () async {
      final controller = await aZuluHelper();
      expect(controller.showEnglish, isFalse);
      controller.toggleEnglish();
      expect(controller.showEnglish, isTrue);
    });
  });

  group('reading aloud', () {
    late FakeReadAloud voice;
    const line = TranslatedLine(
      english: 'Open a window',
      text: 'Vula ifasitela',
      source: TranslationSource.machine,
    );

    ReadAloudController readerIn(HelperLanguage language) {
      final reader = ReadAloudController(readAloud: voice)..follow(language);
      addTearDown(reader.dispose);
      return reader;
    }

    setUp(() => voice = FakeReadAloud());

    test(
      'reads her language in its own voice when the phone has one',
      () async {
        final reader = readerIn(HelperLanguage.isiZulu);
        await pumpEventQueue();
        expect(reader.support, VoiceSupport.available);
        await reader.toggle(line);
        expect(voice.spoken.single, ('Vula ifasitela', HelperLanguage.isiZulu));
        expect(reader.speaking, isNull);
      },
    );

    test('reads the English in an English voice when it has none', () async {
      voice.support = VoiceSupport.englishOnly;
      final reader = readerIn(HelperLanguage.xitsonga);
      await pumpEventQueue();
      await reader.toggle(line);
      expect(voice.spoken.single, ('Open a window', HelperLanguage.english));
    });

    test('reads nothing on a phone that cannot speak', () async {
      voice.support = VoiceSupport.none;
      final reader = readerIn(HelperLanguage.isiZulu);
      await pumpEventQueue();
      await reader.toggle(line);
      expect(voice.spoken, isEmpty);
    });

    test('a refused sentence turns the buttons into an explanation', () async {
      voice.refuses = true;
      final reader = readerIn(HelperLanguage.isiZulu);
      await pumpEventQueue();
      await reader.toggle(line);
      expect(reader.support, VoiceSupport.none);
    });

    test('tapping the line being read stops it', () async {
      final reader = readerIn(HelperLanguage.isiZulu);
      await pumpEventQueue();
      final speaking = reader.toggle(line);
      expect(reader.isSpeaking(line), isTrue);
      await reader.toggle(line);
      expect(voice.stops, 1);
      expect(reader.isSpeaking(line), isFalse);
      await speaking;
    });

    test('a new language asks the phone again', () async {
      final reader = readerIn(HelperLanguage.isiZulu);
      await pumpEventQueue();
      voice.support = VoiceSupport.englishOnly;
      reader.follow(HelperLanguage.sesotho);
      expect(reader.support, isNull);
      await pumpEventQueue();
      expect(reader.support, VoiceSupport.englishOnly);
    });
  });
}
