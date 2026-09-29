import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/documents/model/vault_lock_state.dart';
import 'package:nestprep/features/documents/state/vault_lock_controller.dart';

import '../../../support/fake_vault.dart';

/// The vault's lock (documents ADR-0003): it opens only when the phone's own
/// lock says so, and it shuts again on the way to the background, after five
/// idle minutes, or on request.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeDeviceLock device;
  late List<({Duration after, void Function() fire})> timers;
  late VaultLockController lock;

  setUp(() {
    device = FakeDeviceLock();
    timers = [];
    lock = VaultLockController(
      deviceLock: device,
      reason: 'test',
      startTimer: (duration, callback) {
        timers.add((after: duration, fire: callback));
        return Timer(const Duration(days: 1), () {});
      },
    );
  });

  tearDown(() => lock.dispose());

  test('starts locked, and opens when the phone says it is them', () async {
    expect(lock.isUnlocked, isFalse);
    await lock.unlock();
    expect(lock.isUnlocked, isTrue);
    expect(lock.problem, isNull);
    expect(device.asked, 1);
  });

  test('backing out of the prompt stays locked and says nothing', () async {
    device.outcome = UnlockOutcome.cancelled;
    await lock.unlock();
    expect(lock.isUnlocked, isFalse);
    expect(lock.problem, isNull);
  });

  test(
    'a phone with no screen lock never opens the vault, and says why',
    () async {
      device.outcome = UnlockOutcome.noScreenLock;
      await lock.unlock();
      expect(lock.isUnlocked, isFalse);
      expect(lock.problem, UnlockOutcome.noScreenLock);
    },
  );

  test('too many wrong tries is its own answer', () async {
    device.outcome = UnlockOutcome.lockedOut;
    await lock.unlock();
    expect(lock.problem, UnlockOutcome.lockedOut);
  });

  test(
    'shows the prompt as in progress, and asks only once at a time',
    () async {
      device.holdPrompt = Completer<void>();
      final first = lock.unlock();
      expect(lock.state, VaultLockState.unlocking);
      await lock.unlock();
      expect(device.asked, 1);
      device.holdPrompt!.complete();
      await first;
      expect(lock.isUnlocked, isTrue);
    },
  );

  test('locks when the app goes to the background', () async {
    await lock.unlock();
    lock.didChangeAppLifecycleState(AppLifecycleState.paused);
    expect(lock.isUnlocked, isFalse);
  });

  test('does not lock for the moment the prompt itself takes the screen', () async {
    // iOS reports `inactive` while Face ID is up; locking on it would make the
    // vault impossible to open.
    await lock.unlock();
    lock.didChangeAppLifecycleState(AppLifecycleState.inactive);
    expect(lock.isUnlocked, isTrue);
  });

  test('locks five minutes after the last thing opened, and a touch restarts '
      'the five', () async {
    await lock.unlock();
    expect(timers.single.after, VaultLockController.idleLimit);
    lock.touch();
    expect(timers, hasLength(2));
    timers.last.fire();
    expect(lock.isUnlocked, isFalse);
  });

  test('locks on request, and forgets the last problem', () async {
    await lock.unlock();
    lock.lock();
    expect(lock.isUnlocked, isFalse);
    expect(lock.problem, isNull);
  });
}
