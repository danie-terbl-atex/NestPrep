import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/nanny_hub/model/care_routine.dart';
import 'package:nestprep/features/nanny_hub/model/checklist_item.dart';
import 'package:nestprep/features/nanny_hub/model/contact_draft.dart';
import 'package:nestprep/features/nanny_hub/model/contact_kind.dart';
import 'package:nestprep/features/nanny_hub/model/home_sheet.dart';
import 'package:nestprep/features/nanny_hub/model/photo_change.dart';
import 'package:nestprep/features/nanny_hub/model/shift_moment.dart';
import 'package:nestprep/features/nanny_hub/state/hub_edits.dart';
import 'package:nestprep/features/nanny_hub/state/photo_library.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/fake_documents.dart';
import '../../../support/fake_nanny_hub.dart';

void main() {
  late FakeNannyHubRepository repository;
  late FakePhotoStore store;
  late PhotoLibrary photos;
  late HubEdits edit;
  AppFailure? refused;

  setUp(() {
    repository = FakeNannyHubRepository();
    store = FakePhotoStore();
    photos = PhotoLibrary(
      photoStore: store,
      documentDirectory: FakeDocumentDirectory(),
      householdId: 'h1',
      uploaderUid: 'uid-sam',
      compress: (bytes) async => bytes,
    );
    refused = null;
    edit = HubEdits(
      nannyHubRepository: repository,
      photos: photos,
      householdId: 'h1',
      memberId: 'm-sam',
      runAction: (action) async {
        try {
          await action();
        } on AppFailure catch (failure) {
          refused = failure;
        }
      },
    );
  });

  tearDown(() async {
    photos.dispose();
    await repository.close();
  });

  Map<String, Object?> onlyWrite(String method) {
    final (name, arguments) = repository.writes.single;
    expect(name, method);
    return arguments;
  }

  test(
    'a routine is saved trimmed, blank steps dropped, notes blank as null',
    () async {
      await edit.saveRoutines('m-kid', const [
        CareRoutine(label: '  Bath ', minuteOfDay: 1080, note: '  '),
        CareRoutine(label: '   '),
      ]);
      final routines =
          onlyWrite('saveRoutines')['routines']! as List<CareRoutine>;
      expect(routines, const [CareRoutine(label: 'Bath', minuteOfDay: 1080)]);
      expect(onlyWrite('saveRoutines')['write'], (
        householdId: 'h1',
        childId: 'm-kid',
        memberId: 'm-sam',
      ));
    },
  );

  test('comfort items are trimmed and each kept once', () async {
    await edit.saveComfortItems('m-kid', [' Bunny', 'Bunny', '', 'Blanket']);
    expect(onlyWrite('saveComfortItems')['items'], ['Bunny', 'Blanket']);
  });

  test('care notes left blank are saved as nothing', () async {
    await edit.saveCareNotes('m-kid', settling: ' ', goodToKnow: ' Dark ');
    expect(onlyWrite('saveCareNotes')['settling'], isNull);
    expect(onlyWrite('saveCareNotes')['goodToKnow'], 'Dark');
  });

  test('a contact and the sheet are saved tidied, and stamped', () async {
    await edit.addContact(
      const ContactDraft(
        name: ' Gran ',
        kind: ContactKind.backup,
        phone: ' 082 555 0123 ',
        note: ' ',
      ),
    );
    final contact = onlyWrite('addContact');
    expect(contact['name'], 'Gran');
    expect(contact['phone'], '082 555 0123');
    expect(contact['note'], isNull);
    expect(contact['by'], (householdId: 'h1', memberId: 'm-sam'));

    repository.writes.clear();
    await edit.saveSheet(
      const HomeSheet(address: ' 12 Acacia Lane ', medicalAidPlan: ''),
    );
    final sheet = onlyWrite('saveSheet')['sheet']! as HomeSheet;
    expect(sheet.address, '12 Acacia Lane');
    expect(sheet.medicalAidPlan, isNull);
  });

  group('a photo', () {
    test(
      'picked for a new place is stored first, then the place points at it',
      () async {
        await edit.saveGuideSpot(
          title: 'Nappies',
          photo: PhotoPicked(Uint8List.fromList([1])),
        );
        final photoId = onlyWrite('addGuideSpot')['photoId'];
        expect(store.objects.keys, [photoId]);
      },
    );

    test(
      'that replaces another takes the old one out after the write',
      () async {
        store.objects['old'] = Uint8List(1);
        await edit.saveGuideSpot(
          spotId: 'g1',
          title: 'Nappies',
          photo: PhotoPicked(Uint8List.fromList([2])),
          currentPhotoId: 'old',
        );
        expect(onlyWrite('updateGuideSpot')['photoId'], isNot('old'));
        expect(store.removed, ['old']);
      },
    );

    test('kept stays, removed goes', () async {
      await edit.saveGuideSpot(
        spotId: 'g1',
        title: 'Nappies',
        photo: const PhotoKept(),
        currentPhotoId: 'kept',
      );
      expect(onlyWrite('updateGuideSpot')['photoId'], 'kept');
      expect(store.removed, isEmpty);

      repository.writes.clear();
      await edit.saveGuideSpot(
        spotId: 'g1',
        title: 'Nappies',
        photo: const PhotoRemoved(),
        currentPhotoId: 'kept',
      );
      expect(onlyWrite('updateGuideSpot')['photoId'], isNull);
      expect(store.removed, ['kept']);
    });

    test('stored for a write that is then refused is taken back out, and the '
        'refusal is kept', () async {
      repository.failWritesWith = const PermissionDeniedFailure();
      await edit.saveGuideSpot(
        title: 'Nappies',
        photo: PhotoPicked(Uint8List.fromList([1])),
      );
      expect(refused, isA<PermissionDeniedFailure>());
      expect(store.objects, isEmpty);
      expect(store.removed, hasLength(1));
    });

    test('on a card is changed the same way', () async {
      await edit.changeCardPhoto(
        'm-kid',
        PhotoPicked(Uint8List.fromList([3])),
        current: 'before',
      );
      expect(onlyWrite('saveCardPhoto')['photoId'], startsWith('photo-'));
      expect(store.removed, ['before']);
    });

    test('goes with its place when the place is removed', () async {
      await edit.removeGuideSpot('g1', photoId: 'shelf');
      expect(onlyWrite('removeGuideSpot'), {'spotId': 'g1'});
      expect(store.removed, ['shelf']);
    });
  });

  test(
    'a checklist keeps each item’s id, gives new ones one, drops blanks',
    () async {
      await edit.saveChecklist(ShiftMoment.bedtime, const [
        ChecklistItem(id: 'teeth', text: ' Brush teeth '),
        ChecklistItem(id: '', text: 'Night light'),
        ChecklistItem(id: '', text: '  '),
      ]);
      final items = onlyWrite('saveChecklist')['items']! as List<ChecklistItem>;
      expect(items, const [
        ChecklistItem(id: 'teeth', text: 'Brush teeth'),
        ChecklistItem(id: 'item-0', text: 'Night light'),
      ]);
    },
  );

  test('rules are trimmed, and changed and removed by id', () async {
    await edit.addRule(' Bed by 8 ');
    await edit.updateRule('r1', 'Bed by 9 ');
    await edit.removeRule('r1');
    expect(repository.writes.map((write) => write.$2['text']), [
      'Bed by 8',
      'Bed by 9',
      null,
    ]);
  });
}
