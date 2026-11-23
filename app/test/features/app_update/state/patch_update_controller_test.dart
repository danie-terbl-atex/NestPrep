import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/app_update/data/patch_updates.dart';
import 'package:nestprep/features/app_update/state/patch_update_controller.dart';

import '../../../support/fake_app_update.dart';

void main() {
  PatchUpdateController controllerFor(
    FakePatchUpdates updates, {
    bool relaunches = true,
  }) {
    return PatchUpdateController(
      updates: updates,
      restarter: FakeAppRestarter(relaunches: relaunches),
    );
  }

  testWidgets('a downloaded patch holds the app for a restart', (tester) async {
    final controller = controllerFor(
      FakePatchUpdates([PatchReadiness.readyOnRestart]),
    );
    var notified = 0;
    controller.addListener(() => notified++);

    controller.opened();
    await tester.pump();

    expect(controller.restartReady, isTrue);
    expect(controller.canRelaunch, isTrue);
    expect(notified, 1);
    controller.dispose();
  });

  testWidgets('says when the phone can only close the app', (tester) async {
    final controller = controllerFor(
      FakePatchUpdates([PatchReadiness.readyOnRestart]),
      relaunches: false,
    );

    controller.opened();
    await tester.pump();

    expect(controller.restartReady, isTrue);
    expect(controller.canRelaunch, isFalse);
    controller.dispose();
  });

  testWidgets('a patch still downloading is looked at again until it lands', (
    tester,
  ) async {
    final updates = FakePatchUpdates([
      PatchReadiness.downloading,
      PatchReadiness.downloading,
      PatchReadiness.readyOnRestart,
    ]);
    final controller = controllerFor(updates);

    controller.opened();
    await tester.pump();
    expect(controller.restartReady, isFalse);

    await tester.pump(controller.downloadPoll);
    await tester.pump(controller.downloadPoll);

    expect(updates.checks, 3);
    expect(controller.restartReady, isTrue);
    controller.dispose();
  });

  testWidgets('gives up on a download that never lands', (tester) async {
    final updates = FakePatchUpdates(
      List.filled(100, PatchReadiness.downloading),
    );
    final controller = controllerFor(updates);

    controller.opened();
    await tester.pump();
    for (var poll = 0; poll < 50; poll++) {
      await tester.pump(controller.downloadPoll);
    }

    expect(updates.checks, controller.downloadPolls + 1);
    expect(controller.restartReady, isFalse);
    controller.dispose();
  });

  testWidgets('coming back soon after a check does not check again', (
    tester,
  ) async {
    final updates = FakePatchUpdates();
    final controller = controllerFor(updates);

    controller.opened();
    await tester.pump();
    controller.opened();
    await tester.pump(controller.recheckAfter - const Duration(seconds: 1));
    controller.opened();
    await tester.pump();
    expect(updates.checks, 1);

    await tester.pump(const Duration(seconds: 1));
    controller.opened();
    await tester.pump();
    expect(updates.checks, 2);
    controller.dispose();
  });

  testWidgets('a failed check shows nothing and is tried on a later open', (
    tester,
  ) async {
    final updates = FakePatchUpdates()..error = Exception('offline');
    final controller = controllerFor(updates);

    controller.opened();
    await tester.pump();
    expect(controller.restartReady, isFalse);

    updates.error = null;
    await tester.pump(controller.recheckAfter);
    controller.opened();
    await tester.pump();
    expect(updates.checks, 2);
    controller.dispose();
  });

  testWidgets('a second tap does not restart twice', (tester) async {
    final restarter = FakeAppRestarter();
    final controller = PatchUpdateController(
      updates: FakePatchUpdates(),
      restarter: restarter,
    );

    await Future.wait([controller.restart(), controller.restart()]);

    expect(restarter.restarts, 1);
    expect(controller.restarting, isTrue);
    controller.dispose();
  });

  test('disposing stops a pending poll', () async {
    final updates = FakePatchUpdates([PatchReadiness.downloading]);
    final controller = PatchUpdateController(
      updates: updates,
      restarter: FakeAppRestarter(),
      downloadPoll: const Duration(milliseconds: 10),
    );

    controller.opened();
    await Future<void>.delayed(Duration.zero);
    controller.dispose();
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(updates.checks, 1);
  });
}
