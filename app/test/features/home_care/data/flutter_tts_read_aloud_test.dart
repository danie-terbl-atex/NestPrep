import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/home_care/data/flutter_tts_read_aloud.dart';
import 'package:nestprep/features/home_care/data/read_aloud.dart';
import 'package:nestprep/features/home_care/model/language/helper_language.dart';

/// The phone's speech engine as `flutter_tts` reaches it (home-care
/// ADR-0006), with the platform side answered by hand: which voices exist,
/// what a sentence is spoken in, and a refusal read as an answer rather than
/// a crash.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('flutter_tts');
  final calls = <MethodCall>[];
  late Set<String> voices;
  late PlatformException? Function(MethodCall call)? refuse;

  setUp(() {
    calls.clear();
    voices = {'en-ZA', 'zu-ZA'};
    refuse = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          final refusal = refuse?.call(call);
          if (refusal != null) throw refusal;
          return switch (call.method) {
            // Android answers 1 or 0; iOS answers true or false.
            'isLanguageAvailable' => voices.contains(call.arguments) ? 1 : 0,
            'speak' => 1,
            _ => null,
          };
        });
  });

  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null),
  );

  test('a language with a voice on the phone reads in it', () async {
    expect(
      await FlutterTtsReadAloud().supportFor(HelperLanguage.isiZulu),
      VoiceSupport.available,
    );
  });

  test('a language with none falls back to English, and says so', () async {
    expect(
      await FlutterTtsReadAloud().supportFor(HelperLanguage.xitsonga),
      VoiceSupport.englishOnly,
    );
  });

  test('a phone with no voice at all cannot read aloud', () async {
    voices = {};
    expect(
      await FlutterTtsReadAloud().supportFor(HelperLanguage.isiZulu),
      VoiceSupport.none,
    );
  });

  test(
    'an engine that refuses to be asked reads as none, not a crash',
    () async {
      refuse = (call) => PlatformException(code: 'noEngine');
      expect(
        await FlutterTtsReadAloud().supportFor(HelperLanguage.isiZulu),
        VoiceSupport.none,
      );
    },
  );

  test('speaks in the voice asked for, a little slower, after stopping the '
      'last', () async {
    final spoke = await FlutterTtsReadAloud().speak(
      'Vula ifasitela',
      HelperLanguage.isiZulu,
    );
    expect(spoke, isTrue);
    final methods = calls.map((call) => call.method).toList();
    expect(methods, containsAllInOrder(['stop', 'setLanguage', 'speak']));
    expect(
      calls.firstWhere((call) => call.method == 'setLanguage').arguments,
      'zu-ZA',
    );
    expect(
      calls.firstWhere((call) => call.method == 'awaitSpeakCompletion'),
      isNotNull,
    );
  });

  test('a sentence the engine refuses is reported, not thrown', () async {
    refuse = (call) =>
        call.method == 'speak' ? PlatformException(code: 'busy') : null;
    expect(
      await FlutterTtsReadAloud().speak('Sula', HelperLanguage.isiZulu),
      isFalse,
    );
  });
}
