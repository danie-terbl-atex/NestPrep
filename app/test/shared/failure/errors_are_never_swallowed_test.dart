import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// `ENG-10`: errors are never swallowed. An empty catch is a decision to lose
/// data silently, and it is on the workspace's never-skipped list.
///
/// The analyzer already refuses a `catch` with no `on` clause. What no lint
/// looks at is whether the catch *does* anything, and whether a stream's errors
/// have anywhere to go — a `listen` without `onError` sends a rules denial to
/// the zone, where it becomes an unhandled error and a crash report instead of
/// the banner the screen already knows how to draw (`FE-08`).
void main() {
  final repoRoot = Directory.current.parent;

  List<File> sourcesIn(String path, String extension) {
    final directory = Directory('${repoRoot.path}/$path');
    if (!directory.existsSync()) return const [];
    return directory
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith(extension))
        .where((file) => !file.path.endsWith('.g.dart'))
        .where((file) => !file.path.endsWith('.freezed.dart'))
        .toList();
  }

  final dart = sourcesIn('app/lib', '.dart');
  final typescript = sourcesIn('functions/src', '.ts');

  String at(File file, String source, int offset) {
    final line = '\n'.allMatches(source.substring(0, offset)).length + 1;
    return '${file.path.split('/NestPrep/').last}:$line';
  }

  test('it can see both codebases', () {
    expect(dart, isNotEmpty);
    expect(typescript, isNotEmpty);
  });

  test('no catch does nothing at all', () {
    // Deliberately only matches a body with no nested braces — a catch that
    // does something has statements, and this is looking for the ones that do
    // not.
    final emptyCatch = RegExp(r'catch\s*\([^)]*\)\s*\{([^{}]*)\}');
    final comment = RegExp(r'//[^\n]*');
    final offences = <String>[];

    for (final file in [...dart, ...typescript]) {
      final source = file.readAsStringSync();
      for (final match in emptyCatch.allMatches(source)) {
        final body = match.group(1)!.replaceAll(comment, '').trim();
        if (body.isEmpty) {
          offences.add('${at(file, source, match.start)}  an empty catch');
        }
      }
    }

    expect(
      offences,
      isEmpty,
      reason: 'an empty catch is a decision to lose data silently (`ENG-10`)',
    );
  });

  test('every stream a screen depends on sends its errors somewhere', () {
    final listen = RegExp(r'\.listen\(', multiLine: true);
    final offences = <String>[];

    for (final file in dart) {
      final source = file.readAsStringSync();
      for (final match in listen.allMatches(source)) {
        // The call runs to the matching close paren; `onError` has to be in it.
        var depth = 0;
        var index = match.end - 1;
        for (; index < source.length; index++) {
          if (source[index] == '(') depth++;
          if (source[index] == ')') {
            depth--;
            if (depth == 0) break;
          }
        }
        final call = source.substring(match.start, index);
        if (!call.contains('onError')) {
          offences.add(
            '${at(file, source, match.start)}  a listen with no onError',
          );
        }
      }
    }

    expect(
      offences,
      isEmpty,
      reason:
          'an error on a listener with no onError goes to the zone, where '
          'it is an unhandled crash instead of the screen saying what '
          'happened (`ENG-10`, `FE-08`)',
    );
  });

  test('nothing quietly discards a future', () {
    final offences = <String>[];
    for (final file in dart) {
      final source = file.readAsStringSync();
      for (final match in RegExp(r'\.catchError\(').allMatches(source)) {
        offences.add('${at(file, source, match.start)}  .catchError');
      }
    }

    expect(
      offences,
      isEmpty,
      reason:
          'failures reach a screen through AppFailure and a controller, '
          'not through a callback that returns a fallback value',
    );
  });

  // `unawaited` drops the future's errors into the zone. That is fine when the
  // future cannot fail, or handles its own — and it is how crash reporting
  // nearly took the app down with it: the shell called `setMember` without
  // awaiting, so a Crashlytics failure became an unhandled error, and
  // `PlatformDispatcher.onError` reported *that* by calling Crashlytics again.
  //
  // So each one is listed with why it is safe. A new name here is a fire and
  // forget nobody has thought about yet, and a name that has gone is an excuse
  // waiting to be handed to something else.
  const accountedFor = {
    // Cancelling a subscription in dispose. There is no screen left to tell.
    '_cancel()',
    // The same, for the listener sets documents phase 2 keeps apart from its
    // controllers — and for a vault listener closed because its grant was
    // revoked, whose documents have already left the screen (documents
    // ADR-0002).
    '_listeners.stop()',
    '_stop()',
    '_subscriptions.remove(key)?.cancel()',
    '_authSubscription?.cancel()',
    '_accountSubscription?.cancel()',
    // Cancel and re-listen; the new stream's errors go to its onError.
    '_resubscribeToWindow()',
    '_resubscribeToWeek()',
    // Handles its own failure — it goes through `bestEffort`.
    'CrashReporting.setMember(memberId)',
    // The reporter itself. `bestEffort` is the one named place the app
    // swallows an error, and it catches `Object` — so nothing escapes into
    // the zone, which is where reporting would report itself.
    "bestEffort('crashlytics report'",
    // `signOut` catches its own AppFailure.
    '_failSession(error is AppFailure ? error : UnknownFailure(error))',
    // Controllers that keep a refusal instead of throwing it.
    'controller.joinWithCode(_code.text.trim())',
    'controller.createHousehold(',
    // The same shape for the two ways in that are not Google: both keep their
    // AppFailure for the screen's banner (accounts ADR-0002).
    'controller.register(',
    'controller.send(_email.text)',
    // Goes through `runAction`, which keeps an AppFailure for the banner.
    '_resumeReporting(',
    // The window closing is nobody's request at that moment, so it has nowhere
    // to throw; it catches its own AppFailure and puts it on `problems`.
    '_closeWindow()',
    // Already failing: the position stream gave up, and the failure that
    // caused it is on `problems` on the next line.
    '_stopReporting()',
    // Puts the household claim on the token before anything touches Storage
    // (documents ADR-0001). It catches its own `AppFailure` and holds it for
    // the screen's banner, so nothing escapes; it is unawaited because a
    // controller's constructor cannot wait and the listeners must open now.
    '_openStorageAccess()',
    // Counting a household as opened (product-analytics ADR-0001). The
    // heartbeat runs the call through `bestEffort`, which logs a failure and
    // never throws, so nothing can escape; nobody waits on it by design.
    '_heartbeat.beat(',
    // household phase 2 (household ADR-0003). Each keeps its own outcome:
    // `save` and `invite` hold an AppFailure for the screen's banner through
    // their runners, and the share sheet turns a PlatformException into
    // `InviteShareOutcome.unavailable`, which the screen says in words.
    'controller.save()',
    '_invite(context controller role)',
    'controller.shareAgain(invite)',
    'context.read<InviteSharer>().shareCode(',
    // Which calendars this deployment can connect (calendar ADR-0003). It
    // catches its own `AppFailure` and holds it as the availability's failed
    // state, which the screen reads as "try it and see"; it is unawaited for
    // the same reason as the one above.
    '_loadAvailability()',
    // Closing the upload's own progress stream once it has ended. There is
    // nobody left to tell: the failure, if there was one, has already been
    // put on that stream and delivered.
    '_close()',
    // The kid home closing the reads a narrowed grant no longer allows
    // (accounts ADR-0004). Cancelling a listener has no failure to report:
    // anything it was going to say has already reached `_onError`.
    'subscription.cancel())',
    // A child's stars following the kid home (todos ADR-0003): `_reopen`
    // only cancels listeners and opens new ones, whose failures go to their
    // own onError and onto the stars' state.
    '_reopen(show: show))',
    // Family profiles re-reading when a changed grant moves which profiles
    // the viewer may read (family-profiles ADR-0002). `retry` puts any
    // failure on the roster the screen renders.
    'retry())',
  };

  /// Every `unawaited(...)` argument in the app, as written.
  List<({String where, String argument})> everyFireAndForget() {
    final found = <({String where, String argument})>[];
    for (final file in dart) {
      final source = file.readAsStringSync();
      for (final match in RegExp(
        r'unawaited\(\s*([^\n]*)',
      ).allMatches(source)) {
        found.add((
          where: at(file, source, match.start),
          argument: (match.group(1) ?? '').trim().replaceAll(',', ''),
        ));
      }
    }
    return found;
  }

  test('every fire-and-forget future has somewhere for its failure to go', () {
    final unaccounted = [
      for (final call in everyFireAndForget())
        if (!accountedFor.any(call.argument.startsWith))
          '${call.where}  ${call.argument}',
    ];

    expect(
      unaccounted,
      isEmpty,
      reason:
          'an unawaited future whose failure nobody handles becomes an '
          'unhandled error, and the thing that reports unhandled errors is '
          'itself an unawaited future (`ENG-10`)',
    );
  });

  test('and nothing is excused that no longer exists', () {
    // A dead entry on that list reads as a considered exemption while
    // permitting nothing, and it is one rename away from quietly excusing
    // something new. The previous entry was `'() async {'`, which stopped
    // existing the moment the reporter was given a name.
    final arguments = everyFireAndForget().map((call) => call.argument);

    final dead = [
      for (final excuse in accountedFor)
        if (!arguments.any((argument) => argument.startsWith(excuse))) excuse,
    ];

    expect(dead, isEmpty, reason: 'delete it, or it will excuse the next one');
  });

  test('and no lint about errors has been silenced', () {
    final silenced = RegExp(
      r'//\s*ignore(_for_file)?:[^\n]*'
      r'(empty_catches|avoid_catches_without_on_clauses|unawaited_futures'
      r'|discarded_futures|only_throw_errors)',
    );
    final offences = <String>[];
    for (final file in dart) {
      final source = file.readAsStringSync();
      for (final match in silenced.allMatches(source)) {
        offences.add('${at(file, source, match.start)}  ${match.group(0)}');
      }
    }

    expect(
      offences,
      isEmpty,
      reason:
          'the rule is the point; silencing it one line at a time is how '
          'it stops being true',
    );
  });
}
