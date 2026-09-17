import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/diagnostics/model/emulator_ping.dart';
import 'package:nestprep/features/diagnostics/state/ping_list_controller.dart';
import 'package:nestprep/shared/async/async_state.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/fake_ping_repository.dart';

void main() {
  late FakePingRepository repository;
  late PingListController controller;

  setUp(() {
    repository = FakePingRepository();
    controller = PingListController(repository, sentFrom: 'test');
  });

  tearDown(() async {
    controller.dispose();
    await repository.close();
  });

  test('starts loading and shows data when the stream emits', () async {
    expect(controller.pings, isA<AsyncLoading<List<EmulatorPing>>>());
    repository.emit(const [EmulatorPing(id: '1', sentFrom: 'a')]);
    await pumpEventQueue();
    final state = controller.pings;
    expect(state, isA<AsyncData<List<EmulatorPing>>>());
    expect((state as AsyncData<List<EmulatorPing>>).value, hasLength(1));
  });

  test('a stream error becomes a failure and retry resubscribes', () async {
    repository.emitError(const PermissionDeniedFailure());
    await pumpEventQueue();
    expect(controller.pings, isA<AsyncFailure<List<EmulatorPing>>>());

    await controller.retry();
    expect(controller.pings, isA<AsyncLoading<List<EmulatorPing>>>());
    expect(repository.subscriptions, 2);
  });

  test('sending a ping cannot double-submit and reports who sent it', () async {
    final first = controller.sendPing();
    final second = controller.sendPing();
    expect(controller.isSending, isTrue);
    await Future.wait([first, second]);
    expect(repository.sent, ['test']);
    expect(controller.isSending, isFalse);
  });

  test(
    'a failed send is kept for the screen and cleared on the next try',
    () async {
      repository.failSendWith = const UnavailableFailure();
      await controller.sendPing();
      expect(controller.sendFailure, isA<UnavailableFailure>());

      repository.failSendWith = null;
      await controller.sendPing();
      expect(controller.sendFailure, isNull);
    },
  );
}
