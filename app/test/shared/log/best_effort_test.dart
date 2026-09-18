import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/shared/log/best_effort.dart';

/// The one place the app deliberately swallows an error, so the one place that
/// most needs a test.
///
/// It had none. The swallow lived inside a private closure in `CrashReporting`,
/// written twice — once for a report and once for the member id — and a private
/// closure reached only through `FirebaseCrashlytics.instance` cannot be called
/// from a test at all. Which is how the reporter's own error path came to be
/// changed twice in one day with nothing checking it.
void main() {
  group('when the work succeeds', () {
    test('it reports no error', () async {
      expect(await bestEffort('a thing', code: 'x', run: () async {}), isNull);
    });

    test('it actually runs the work', () async {
      var ran = false;
      await bestEffort('a thing', code: 'x', run: () async => ran = true);
      expect(ran, isTrue);
    });

    test('it waits for the work rather than starting it and leaving', () async {
      // Otherwise a report is abandoned half-sent, which looks exactly like a
      // report that was never made.
      var finished = false;
      await bestEffort(
        'a thing',
        code: 'x',
        run: () async {
          await Future<void>.delayed(Duration.zero);
          finished = true;
        },
      );
      expect(finished, isTrue);
    });
  });

  group('when the work throws', () {
    test('it does not throw at the caller', () async {
      // This is the whole point. The caller is a crash handler; a throw here
      // is handed back to the handler that was already reporting.
      await expectLater(
        bestEffort(
          'a thing',
          code: 'x',
          run: () async => throw StateError('crashlytics is down'),
        ),
        completes,
      );
    });

    test('it hands back the error it swallowed, so it is not lost', () async {
      final swallowed = await bestEffort(
        'a thing',
        code: 'boom',
        run: () async => throw StateError('crashlytics is down'),
      );

      expect(swallowed, isA<StateError>());
      expect((swallowed! as StateError).message, 'crashlytics is down');
    });

    test('a synchronous throw is caught too', () async {
      // `run` is typed as async, but a body that throws before its first await
      // throws synchronously when called — and a try that only guards the await
      // would miss it.
      expect(
        await bestEffort(
          'a thing',
          code: 'x',
          run: () => throw StateError('immediately'),
        ),
        isA<StateError>(),
      );
    });

    test('it catches an Error, which `on Exception` would let past', () async {
      // Worth stating rather than assuming: `StateError` is an `Error`, and an
      // `Error` does not implement `Exception`. Everything the platform throws
      // at a crash handler — a type error, an assertion, a state error — is on
      // that side of the split, so `on Object` is the only clause that holds.
      final swallowed = await bestEffort(
        'a thing',
        code: 'x',
        run: () async => throw StateError('from the platform'),
      );

      expect(swallowed, isA<Error>());
      expect(swallowed, isNot(isA<Exception>()));
    });
  });
}
