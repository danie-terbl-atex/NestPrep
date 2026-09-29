import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/async/async_state.dart';
import '../../../shared/failure/app_failure.dart';
import '../../../shared/state/action_failure.dart';
import '../data/helper_profile_repository.dart';
import '../data/translation_repository.dart';
import '../model/home_care_access.dart';
import '../model/language/helper_language.dart';
import '../model/language/helper_profile.dart';
import '../model/language/translated_line.dart';
import 'translation_fetch.dart';

/// Which language the viewer reads home care in, everybody's languages for
/// family, and the lines translated so far (home-care ADR-0006).
///
/// Home-care-wide: the step-through, today's rooms and the languages screen
/// all read it, and a language changed on one shows on the others at once.
/// Everything is English while the switch is off, and nothing is read.
final class HelperLanguageController extends ChangeNotifier
    with ActionFailureHolder {
  HelperLanguageController({
    required this._profileRepository,
    required TranslationRepository translationRepository,
    required this.householdId,
  }) : _fetch = TranslationFetch(
         repository: translationRepository,
         householdId: householdId,
       ) {
    _fetch.addListener(notifyListeners);
  }

  final HelperProfileRepository _profileRepository;
  final TranslationFetch _fetch;
  final String householdId;

  HomeCareAccess? _access;
  var _isOn = false;
  StreamSubscription<List<HelperProfile>>? _subscription;
  Map<String, HelperProfile> _profiles = const {};
  AsyncState<void> _profilesState = const AsyncLoading();
  var _showEnglish = false;
  var _isDisposed = false;

  /// Whether the switch is on and home care is open to the viewer.
  bool get isAvailable => _isOn && (_access?.isVisible ?? false);

  /// The language the viewer reads in.
  HelperLanguage get language => isAvailable
      ? languageOf(_access?.viewerMemberId) ?? HelperLanguage.english
      : HelperLanguage.english;

  /// Whether the languages have been read — for the languages screen's
  /// loading and error states (`FE-08`). The value is in [languageOf].
  AsyncState<void> get profilesState => _profilesState;

  /// A member's chosen language, or null while nobody has chosen one.
  HelperLanguage? languageOf(String? memberId) =>
      memberId == null ? null : _profiles[memberId]?.language;

  /// Whether the English stays beside each translated step.
  bool get showEnglish => _showEnglish;

  bool get isTranslating => _fetch.isBusy;

  /// Why the last translation did not happen, while English is shown instead.
  AppFailure? get translationFailure => _fetch.failure;

  /// [english] as the viewer reads it.
  TranslatedLine lineFor(String english) =>
      _fetch.bookFor(language).lineFor(english);

  /// Asks for whatever of [texts] is not translated yet — the cache first,
  /// then the Function. Safe to call on every build: a text asked for once is
  /// not asked for again while it is on its way.
  void ensure(Iterable<String> texts) {
    if (!language.needsTranslation) return;
    _fetch.ensure(language, texts);
  }

  /// Asks again after a failure.
  void retryTranslation(Iterable<String> texts) {
    _fetch.forgetFailure();
    ensure(texts);
  }

  void toggleEnglish() {
    _showEnglish = !_showEnglish;
    notifyListeners();
  }

  Future<void> setLanguage(String memberId, HelperLanguage next) => runAction(
    () => _profileRepository.setLanguage(
      householdId: householdId,
      memberId: memberId,
      language: next,
      by: _access?.viewerMemberId ?? '',
    ),
  );

  /// The shell's grant or the switch changed. Called while the shell builds,
  /// so it says nothing itself unless what it reads moved.
  void follow(HomeCareAccess access, {required bool isOn}) {
    final scopeMoved =
        access.jobScope != _access?.jobScope ||
        access.isVisible != _access?.isVisible ||
        isOn != _isOn;
    _access = access;
    _isOn = isOn;
    if (!scopeMoved) return;
    unawaited(_listen());
    // After this build, so every screen reading the language hears the
    // switch flip or the grant change.
    scheduleMicrotask(() {
      if (!_isDisposed) notifyListeners();
    });
  }

  Future<void> _listen() async {
    await _subscription?.cancel();
    _subscription = null;
    _profiles = const {};
    _profilesState = const AsyncLoading();
    final access = _access;
    if (!_isOn || access == null || !access.isVisible) return;
    final own = access.jobScope;
    _subscription =
        (own == null
                ? _profileRepository.watchProfiles(householdId)
                : _profileRepository
                      .watchProfile(householdId, own)
                      .map((profile) => [?profile]))
            .listen(_onProfiles, onError: _onError);
  }

  void _onProfiles(List<HelperProfile> profiles) {
    _profiles = {for (final profile in profiles) profile.id: profile};
    _profilesState = const AsyncData(null);
    notifyListeners();
  }

  void _onError(Object error) {
    // The language cannot be read: English stands, and the screen says why.
    _profilesState = AsyncFailure(
      error is AppFailure ? error : UnknownFailure(error),
    );
    notifyListeners();
  }

  /// Reads the languages again after they failed.
  Future<void> retryProfiles() => _listen().then((_) => notifyListeners());

  @override
  void dispose() {
    _isDisposed = true;
    _fetch
      ..removeListener(notifyListeners)
      ..dispose();
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
