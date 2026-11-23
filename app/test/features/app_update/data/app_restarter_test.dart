import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/app_update/data/app_restarter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  void answer(Object? Function(MethodCall call)? handler) =>
      messenger.setMockMethodCallHandler(
        PlatformAppRestarter.channel,
        handler == null ? null : (call) async => handler(call),
      );

  tearDown(() => answer(null));

  test('without a native handler it closes the app', () async {
    var exits = 0;
    final restarter = PlatformAppRestarter(exitApp: () async => exits++);

    expect(await restarter.canRelaunch(), isFalse);
    await restarter.restart();

    expect(exits, 1);
  });

  test('relaunches where Android can, and closes if it did not', () async {
    final calls = <String>[];
    answer((call) {
      calls.add(call.method);
      return call.method == 'canRelaunch' ? true : null;
    });
    var exits = 0;
    final restarter = PlatformAppRestarter(
      exitApp: () async => exits++,
      relaunchGrace: const Duration(milliseconds: 50),
    );

    final restarting = restarter.restart();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(calls, ['canRelaunch', 'relaunch']);
    expect(exits, 0);

    await restarting;
    expect(exits, 1);
  });

  test('a relaunch that fails closes the app at once', () async {
    answer((call) {
      if (call.method == 'canRelaunch') return true;
      throw PlatformException(code: 'no-launcher');
    });
    var exits = 0;
    final restarter = PlatformAppRestarter(
      exitApp: () async => exits++,
      relaunchGrace: const Duration(hours: 1),
    );

    await restarter.restart();

    expect(exits, 1);
  });
}
