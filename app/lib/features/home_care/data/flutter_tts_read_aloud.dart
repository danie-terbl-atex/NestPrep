import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../../shared/log/app_log.dart';
import '../model/language/helper_language.dart';
import 'read_aloud.dart';

/// Read-aloud through the platform's speech engine — Google's on Android,
/// Apple's on iOS — with `flutter_tts` (home-care ADR-0006).
///
/// The plugin answers with untyped values; each one is read here, at the
/// edge, and never cast (`ENG-09`). A voice that is missing is an answer, not
/// an error: the caller offers the English one instead.
final class FlutterTtsReadAloud implements ReadAloud {
  FlutterTtsReadAloud([FlutterTts? tts]) : _tts = tts ?? FlutterTts();

  final FlutterTts _tts;
  var _isReady = false;

  Future<void> _ready() async {
    if (_isReady) return;
    // `speak` then completes when the sentence ends or is stopped, which is
    // what lets the screen show which line is being read.
    await _tts.awaitSpeakCompletion(true);
    _isReady = true;
  }

  @override
  Future<VoiceSupport> supportFor(HelperLanguage language) async {
    try {
      if (await _hasVoice(language)) return VoiceSupport.available;
      return await _hasVoice(HelperLanguage.english)
          ? VoiceSupport.englishOnly
          : VoiceSupport.none;
    } on PlatformException catch (error) {
      AppLog.failure('read aloud', code: error.code, error: error);
      return VoiceSupport.none;
    } on MissingPluginException catch (error) {
      AppLog.failure('read aloud', code: 'noEngine', error: error);
      return VoiceSupport.none;
    }
  }

  Future<bool> _hasVoice(HelperLanguage language) async =>
      _isYes(await _tts.isLanguageAvailable(language.voice));

  @override
  Future<bool> speak(String text, HelperLanguage voice) async {
    try {
      await _ready();
      await _tts.stop();
      await _tts.setLanguage(voice.voice);
      // A little slower than the engine's default: these are instructions to
      // follow, often heard over running water.
      await _tts.setSpeechRate(_speechRate);
      return _isYes(await _tts.speak(text));
    } on PlatformException catch (error) {
      AppLog.failure('read aloud', code: error.code, error: error);
      return false;
    } on MissingPluginException catch (error) {
      AppLog.failure('read aloud', code: 'noEngine', error: error);
      return false;
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _tts.stop();
    } on PlatformException catch (error) {
      AppLog.failure('read aloud', code: error.code, error: error);
    } on MissingPluginException catch (error) {
      AppLog.failure('read aloud', code: 'noEngine', error: error);
    }
  }

  static const _speechRate = 0.42;

  /// The plugin answers `true`, `1` or a string depending on the platform.
  static bool _isYes(Object? answer) => switch (answer) {
    final bool yes => yes,
    final int code => code == 1,
    final String text => text == 'true' || text == '1',
    _ => false,
  };
}
