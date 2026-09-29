import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/nanny_hub/model/nanny_pickups.dart';
import 'package:nestprep/features/nanny_hub/model/photo_change.dart';
import 'package:nestprep/features/nanny_hub/model/pickup_collector.dart';
import 'package:nestprep/features/nanny_hub/model/pickup_drafts.dart';
import 'package:nestprep/features/nanny_hub/state/photo_library.dart';
import 'package:nestprep/features/nanny_hub/state/pickup_controller.dart';
import 'package:nestprep/shared/async/async_state.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:nestprep/shared/time/calendar_date.dart';

import '../../../support/fake_documents.dart';
import '../../../support/fake_nanny_hub.dart';
import '../../../support/fake_nanny_pickups.dart';
import '../../../support/nanny_pickup_fixtures.dart';

void main() {
  late FakePickupRepository repository;
  late FakePhotoStore store;
  late PhotoLibrary photos;
  late PickupController controller;
  final today = CalendarDate(2026, 9, 29);

  setUp(() {
    repository = FakePickupRepository();
    store = FakePhotoStore();
    photos = PhotoLibrary(
      photoStore: store,
      documentDirectory: FakeDocumentDirectory(),
      householdId: 'h1',
      uploaderUid: 'uid-sam',
      compress: (bytes) async => bytes,
    );
    controller = PickupController(
      pickupRepository: repository,
      photos: photos,
      householdId: 'h1',
      memberId: 'm-sam',
      canEdit: true,
      today: today,
    );
  });

  tearDown(() async {
    controller.dispose();
    photos.dispose();
    await repository.close();
  });

  const draft = (
    name: ' Gogo ',
    relationship: 'Gran',
    idNote: '',
    phone: null,
    childIds: {'m-kid'},
  );

  test('waits for all three reads, then holds them as one value', () async {
    repository.people.add([PickupFixtures.gogo]);
    repository.runs.add([]);
    await pumpEventQueue();
    expect(controller.pickups, isA<AsyncLoading<NannyPickups>>());
    repository.changes.add([]);
    await pumpEventQueue();
    final value = (controller.pickups as AsyncData<NannyPickups>).value;
    expect(value.people, [PickupFixtures.gogo]);
  });

  test(
    'asks for the changes from the household’s today, not the past',
    () async {
      expect(repository.changesFrom, today);
    },
  );

  test('asks the photo library for everybody’s photo', () async {
    store.objects['photo-gogo-01'] = Uint8List(1);
    repository.emitAll(peopleList: [PickupFixtures.gogo]);
    await pumpEventQueue();
    expect(store.reads, ['photo-gogo-01']);
  });

  test('a failed read is the screen’s failure to show', () async {
    repository.people.addError(const NotFoundFailure());
    await pumpEventQueue();
    expect(controller.pickups, isA<AsyncFailure<NannyPickups>>());
  });

  test(
    'a new person’s photo is stored before the person, and tidied',
    () async {
      await controller.savePerson(
        draft,
        photo: PhotoPicked(Uint8List.fromList([1, 2])),
      );
      final (method, arguments) = repository.writes.single;
      expect(method, 'addPerson');
      expect(arguments['photoId'], isNotNull);
      expect(store.objects.containsKey(arguments['photoId']), isTrue);
      final saved = arguments['draft']! as PickupPersonDraft;
      expect(saved.name, 'Gogo');
      expect(saved.idNote, isNull);
      expect(arguments['memberId'], 'm-sam');
    },
  );

  test('a refused person takes their photo back out and says why', () async {
    repository.failWritesWith = const PermissionDeniedFailure();
    await controller.savePerson(
      draft,
      photo: PhotoPicked(Uint8List.fromList([1, 2])),
    );
    expect(store.objects, isEmpty);
    expect(store.removed, hasLength(1));
    expect(controller.actionFailure, const PermissionDeniedFailure());
  });

  test(
    'a replaced photo is discarded after the person points elsewhere',
    () async {
      store.objects['old'] = Uint8List(1);
      await controller.savePerson(
        draft,
        personId: 'p-gogo',
        photo: const PhotoRemoved(),
        currentPhotoId: 'old',
      );
      expect(repository.writes.single.$1, 'updatePerson');
      expect(repository.writes.single.$2['photoId'], isNull);
      expect(store.removed, ['old']);
    },
  );

  test('removing a person removes them, then their photo', () async {
    await controller.removePerson(PickupFixtures.gogo);
    expect(repository.writes.single.$1, 'removePerson');
    expect(repository.writes.single.$2, {'personId': 'p-gogo'});
    expect(store.removed, ['photo-gogo-01']);
  });

  test('a run and a change are saved with blank words as nothing', () async {
    await controller.saveRun((
      childId: 'm-kid',
      weekday: 2,
      collector: const CollectedByPerson('p-gogo'),
      atMinute: 870,
      place: '   ',
    ));
    await controller.saveChange((
      childId: 'm-kid',
      date: today,
      collector: const NobodyCollects(),
      atMinute: null,
      note: ' No school ',
    ));
    final run = repository.writes[0].$2['draft']! as SchoolRunDraft;
    final change = repository.writes[1].$2['draft']! as PickupChangeDraft;
    expect(run.place, isNull);
    expect(change.note, 'No school');
    expect(change.collector, const NobodyCollects());
  });

  test('a run is cleared by its child-and-weekday id', () async {
    await controller.removeRun('m-kid', 3);
    expect(repository.writes.single.$1, 'removeRun');
    expect(repository.writes.single.$2, {'runId': 'm-kid_3'});
  });

  test(
    'a second tap while a change is saving is not a second change',
    () async {
      final first = controller.removeRun('m-kid', 3);
      final second = controller.removeRun('m-kid', 4);
      expect(controller.isSaving, isTrue);
      await Future.wait([first, second]);
      expect(repository.writes, hasLength(1));
      expect(controller.isSaving, isFalse);
    },
  );
}
