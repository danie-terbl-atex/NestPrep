import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/read_aloud.dart';
import '../model/language/helper_language.dart';
import '../model/language/translated_line.dart';

/// Reading a line aloud in the viewer's language, or its English when the
/// phone has no voice for that language — and saying which (home-care
/// ADR-0006). Speaking again stops the line before.
final class ReadAloudController extends ChangeNotifier {
  ReadAloudController({required this._readAloud});

  final ReadAloud _readAloud;

  HelperLanguage? _language;
  VoiceSupport? _support;
  String? _speaking;
  var _isDisposed = false;

  /// What this phone can do for the viewer's language; null until asked.
  VoiceSupport? get support => _support;

  /// The English of the line being read, so its button shows *stop*.
  String? get speaking => _speaking;

  bool isSpeaking(TranslatedLine line) => _speaking == line.english;

  /// The viewer's language changed: find out what the phone can do for it.
  void follow(HelperLanguage language) {
    if (language == _language) return;
    _language = language;
    _support = null;
    unawaited(_ask(language));
  }

  Future<void> _ask(HelperLanguage language) async {
    final support = await _readAloud.supportFor(language);
    if (_isDisposed || language != _language) return;
    _support = support;
    notifyListeners();
  }

  /// Reads [line] — in her language when there is a voice for it, else the
  /// English in an English voice — or stops it if it is being read.
  Future<void> toggle(TranslatedLine line) async {
    if (isSpeaking(line)) return stop();
    final language = _language;
    final support = _support;
    if (language == null || support == null || support == VoiceSupport.none) {
      return;
    }
    final inHerVoice = support == VoiceSupport.available;
    _speaking = line.english;
    notifyListeners();
    final didSpeak = await _readAloud.speak(
      inHerVoice ? line.text : line.english,
      inHerVoice ? language : HelperLanguage.english,
    );
    if (_isDisposed) return;
    // The engine refused — the button now explains rather than doing nothing.
    if (!didSpeak) _support = VoiceSupport.none;
    if (_speaking == line.english) _speaking = null;
    notifyListeners();
  }

  Future<void> stop() async {
    _speaking = null;
    notifyListeners();
    await _readAloud.stop();
  }

  @override
  void dispose() {
    _isDisposed = true;
    unawaited(_readAloud.stop());
    super.dispose();
  }
}
