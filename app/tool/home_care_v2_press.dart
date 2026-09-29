import 'package:nestprep/features/home_care/data/translation_repository.dart';
import 'package:nestprep/features/home_care/model/language/helper_language.dart';
import 'package:nestprep/features/home_care/model/language/helper_profile.dart';
import 'package:nestprep/features/home_care/state/helper_language_controller.dart';
import 'package:nestprep/features/home_care/state/home_care_controller.dart';
import 'package:nestprep/features/home_care/state/read_aloud_controller.dart';
import 'package:nestprep/shared/flags/feature_flags_controller.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../test/support/fake_feature_flag_source.dart';
import '../test/support/fake_home_care_v2.dart';
import '../test/support/household_fixtures.dart';

/// IsiZulu for the fixture's words, for pictures only — so the press shows a
/// helper's screen as she would see it rather than `[zu]` markers. Not a
/// reviewed translation of anything, and never shipped.
const _pictureZulu = {
  'Open a window': 'Vula ifasitela',
  'Spray and leave for five minutes': 'Fafaza bese ushiya imizuzu emihlanu',
  'Wipe clean': 'Sula kuze kuhlanzeke',
  'Wipe the counters': 'Sula amakhawunta',
  'Sweep the floor': 'Shanela phansi',
  'Empty the bin': 'Thulula umgqomo',
  'Open a window before you start cleaning.':
      'Vula ifasitela ngaphambi kokuthi uqale ukuhlanza.',
};

/// A translation cache that holds [_pictureZulu] and translates nothing else.
final class PictureTranslations implements TranslationRepository {
  @override
  Future<Map<String, String>> cached({
    required String householdId,
    required HelperLanguage language,
    required List<String> texts,
  }) async => {
    for (final text in texts)
      if (_pictureZulu[text] case final String zulu) text: zulu,
  };

  @override
  Future<Map<String, String>> translate({
    required String householdId,
    required HelperLanguage language,
    required List<String> texts,
  }) async => const {};
}

/// The V2 controllers every home-care screen now reads (home-care ADR-0004
/// to ADR-0006), over fakes: every switch on, and a phone with a voice.
final class HomeCareV2Press {
  HomeCareV2Press(HomeCareController home) {
    languages.follow(home.access, isOn: true);
    _viewer = home.access.viewerMemberId ?? Fixtures.samMemberId;
  }

  final _flagSource = FakeFeatureFlagSource();
  final _profiles = FakeHelperProfileRepository();
  late final _flags = FeatureFlagsController(source: _flagSource);
  late final languages = HelperLanguageController(
    profileRepository: _profiles,
    translationRepository: PictureTranslations(),
    householdId: Fixtures.householdId,
  );
  final reader = ReadAloudController(readAloud: FakeReadAloud());
  late final String _viewer;

  List<SingleChildWidget> get providers => [
    ChangeNotifierProvider<FeatureFlagsController>.value(value: _flags),
    ChangeNotifierProvider<HelperLanguageController>.value(value: languages),
    ChangeNotifierProvider<ReadAloudController>.value(value: reader),
  ];

  /// The viewer reads in [language]; Thandi, when she is not the viewer,
  /// in isiZulu.
  void speak(HelperLanguage language) {
    _profiles.emitProfiles([
      HelperProfile(id: _viewer, language: language, updatedBy: _viewer),
      if (_viewer != Fixtures.thandiMemberId)
        const HelperProfile(
          id: Fixtures.thandiMemberId,
          language: HelperLanguage.isiZulu,
          updatedBy: Fixtures.samMemberId,
        ),
    ]);
  }

  /// After the language has arrived: ask the phone about its voice.
  void listen() => reader.follow(languages.language);

  Future<void> close() async {
    reader.dispose();
    languages.dispose();
    _flags.dispose();
    await _profiles.close();
    await _flagSource.close();
  }
}
