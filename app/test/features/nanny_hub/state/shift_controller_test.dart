import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/nanny_hub/model/handover_draft.dart';
import 'package:nestprep/features/nanny_hub/model/handover_kind.dart';
import 'package:nestprep/features/nanny_hub/model/photo_change.dart';
import 'package:nestprep/features/nanny_hub/model/shift_log.dart';
import 'package:nestprep/features/nanny_hub/model/shift_moment.dart';
import 'package:nestprep/features/nanny_hub/state/photo_library.dart';
import 'package:nestprep/features/nanny_hub/state/shift_controller.dart';
import 'package:nestprep/shared/async/async_state.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/fake_documents.dart';
import '../../../support/fake_nanny_hub.dart';
import '../../../support/nanny_fixtures.dart';

void main() {
  late FakeShiftRepository shifts;
  late FakeShiftDirectory directory;
  late FakePhotoStore store;
  late PhotoLibrary photos;
  late ShiftController controller;

  final draft = HandoverDraft(
    kind: HandoverKind.meal,
    at: DateTime.utc(2026, 9, 29, 15),
    note: 'Pasta',
  );

  setUp(() {
    shifts = FakeShiftRepository();
    directory = FakeShiftDirectory();
    store = FakePhotoStore();
    photos = PhotoLibrary(
      photoStore: store,
      documentDirectory: FakeDocumentDirectory(),
      householdId: 'h1',
      uploaderUid: NannyFixtures.nomsaUid,
      compress: (bytes) async => bytes,
    );
    controller = ShiftController(
      shiftRepository: shifts,
      shiftDirectory: directory,
      photos: photos,
      householdId: 'h1',
      shiftId: 'shift-1',
      memberId: NannyFixtures.nomsaMemberId,
    );
  });

  tearDown(() async {
    controller.dispose();
    photos.dispose();
    await shifts.close();
  });

  test('is loading until the shift and its log have both answered', () async {
    shifts.shift.add(NannyFixtures.openShift);
    await pumpEventQueue();
    expect(controller.log, isA<AsyncLoading<ShiftLog>>());
    shifts.entries.add([NannyFixtures.tea]);
    await pumpEventQueue();
    final log = (controller.log as AsyncData<ShiftLog>).value;
    expect(log.shift?.id, 'shift-1');
    expect(log.newestFirst.single.id, 'e-tea');
  });

  test('a shift that is gone is gone, not a failure', () async {
    shifts.shift.add(null);
    shifts.entries.add(const []);
    await pumpEventQueue();
    expect((controller.log as AsyncData<ShiftLog>).value.isGone, isTrue);
  });

  test('a failed read is the log’s failure, and a retry reads again', () async {
    shifts.entries.addError(const UnavailableFailure());
    await pumpEventQueue();
    expect(controller.log, isA<AsyncFailure<ShiftLog>>());
    await controller.retry();
    expect(controller.log, isA<AsyncLoading<ShiftLog>>());
  });

  test('knows which entries are the viewer’s own', () {
    expect(controller.isMine(NannyFixtures.tea), isTrue);
    expect(
      controller.isMine(NannyFixtures.tea.copyWith(byMemberId: 'm-sam')),
      isFalse,
    );
  });

  test('logs an entry stamped as the viewer’s', () async {
    expect(await controller.addEntry(draft), isTrue);
    final (method, arguments) = shifts.writes.single;
    expect(method, 'addEntry');
    expect(arguments['byMemberId'], NannyFixtures.nomsaMemberId);
    expect(arguments['draft'], draft);
  });

  test(
    'stores the photo first, so the entry never points at nothing',
    () async {
      await controller.addEntry(draft, photo: Uint8List.fromList([7]));
      final written = shifts.writes.single.$2['draft']! as HandoverDraft;
      expect(written.photoId, isNotNull);
      expect(store.objects[written.photoId], [7]);
    },
  );

  test(
    'a refused entry takes its photo back out and keeps the reason',
    () async {
      shifts.failWritesWith = const PermissionDeniedFailure();
      expect(
        await controller.addEntry(draft, photo: Uint8List.fromList([7])),
        isFalse,
      );
      expect(store.objects, isEmpty);
      expect(controller.actionFailure, isA<PermissionDeniedFailure>());
    },
  );

  test(
    'a second log while the first is on its way is not a second entry',
    () async {
      final first = controller.addEntry(draft);
      expect(controller.isSaving, isTrue);
      expect(await controller.addEntry(draft), isFalse);
      await first;
      expect(shifts.writes, hasLength(1));
      expect(controller.isSaving, isFalse);
    },
  );

  test('a changed entry keeps, replaces or drops its photo', () async {
    final withPhoto = NannyFixtures.tea.copyWith(photoId: 'old');
    await controller.updateEntry(withPhoto, draft, photo: const PhotoKept());
    expect((shifts.writes.last.$2['draft']! as HandoverDraft).photoId, 'old');
    await controller.updateEntry(withPhoto, draft, photo: const PhotoRemoved());
    expect((shifts.writes.last.$2['draft']! as HandoverDraft).photoId, isNull);
    expect(store.removed, ['old']);
  });

  test('a removed entry takes its photo with it', () async {
    await controller.removeEntry(NannyFixtures.tea.copyWith(photoId: 'p'));
    expect(shifts.writes.single.$1, 'removeEntry');
    expect(shifts.writes.single.$2, {'entryId': 'e-tea'});
    expect(store.removed, ['p']);
  });

  test('ticks by the moment and the item', () async {
    await controller.setTick(ShiftMoment.dinner, 'table', isTicked: true);
    expect(shifts.writes.single.$2, {
      'tickKey': 'dinner:table',
      'isTicked': true,
    });
  });

  test('ends once, with the closing note trimmed and blank as none', () async {
    directory.gate = Completer<void>();
    final first = controller.end(closingNote: '  ');
    expect(controller.isEnding, isTrue);
    expect(await controller.end(closingNote: 'again'), isFalse);
    directory.gate!.complete();
    expect(await first, isTrue);
    expect(directory.ended, [(shiftId: 'shift-1', closingNote: null)]);

    expect(await controller.end(closingNote: ' Asleep by 8 '), isTrue);
    expect(directory.ended.last.closingNote, 'Asleep by 8');
  });

  test('a refused end says why and says it did not end', () async {
    directory.failWith = const NannyHubFailure(NannyHubProblem.notYourShift);
    expect(await controller.end(), isFalse);
    expect(controller.actionFailure, isA<NannyHubFailure>());
    expect(controller.isEnding, isFalse);
  });
}
