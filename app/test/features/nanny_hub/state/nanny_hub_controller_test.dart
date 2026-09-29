import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/family_profiles/model/member_health.dart';
import 'package:nestprep/features/household/model/household_view.dart';
import 'package:nestprep/features/nanny_hub/data/photo_picker.dart';
import 'package:nestprep/features/nanny_hub/model/nanny_hub_view.dart';
import 'package:nestprep/features/nanny_hub/state/nanny_hub_controller.dart';
import 'package:nestprep/features/nanny_hub/state/photo_library.dart';
import 'package:nestprep/shared/async/async_state.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/fake_family_profiles.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/nanny_fixtures.dart';
import '../../../support/pump_nanny_hub.dart';

void main() {
  late NannyFakes fakes;
  late PhotoLibrary photos;
  late NannyHubController controller;

  NannyHubController build(HouseholdView view) => NannyHubController(
    nannyHubRepository: fakes.hub,
    shiftRepository: fakes.shifts,
    familyProfileRepository: fakes.family,
    householdId: Fixtures.householdId,
    household: view,
    photos: photos,
    photoPicker: fakes.picker,
    linkOpener: fakes.opener,
  );

  setUp(() {
    fakes = NannyFakes();
    photos = PhotoLibrary(
      photoStore: fakes.photos,
      documentDirectory: fakes.documents,
      householdId: Fixtures.householdId,
      uploaderUid: NannyFixtures.nomsaUid,
      compress: (bytes) async => bytes,
    );
    controller = build(NannyFixtures.carerView());
  });

  tearDown(() async {
    controller.dispose();
    photos.dispose();
    await fakes.close();
  });

  NannyHubView loaded() => switch (controller.view) {
    AsyncData(:final value) => value,
    final other => fail('the hub has not loaded: $other'),
  };

  test('stays loading until all eight of its reads have answered', () async {
    fakes.hub.emitAll();
    fakes.shifts.openShifts.add(const []);
    await pumpEventQueue();
    expect(controller.view, isA<AsyncLoading<NannyHubView>>());
    fakes.shifts.summaries.add(const []);
    await pumpEventQueue();
    expect(controller.view, isA<AsyncData<NannyHubView>>());
  });

  test(
    'one read failing is the hub’s failure, and a retry starts again',
    () async {
      fakes.hub.rules.addError(const UnavailableFailure());
      await pumpEventQueue();
      expect(controller.view, isA<AsyncFailure<NannyHubView>>());
      await controller.retry();
      fakes.answerAFullHub();
      await pumpEventQueue();
      expect(loaded().hub.rules.single.text, 'No screens after six');
    },
  );

  test('joins the hub with the children and their allergies', () async {
    fakes.answerAFullHub();
    await pumpEventQueue();
    final kid = loaded().childById(Fixtures.kidMemberId)!;
    expect(kid.card.comfortItems, ['Blue bunny']);
    expect(kid.food, isA<AsyncData<Object?>>());
  });

  test('asks for the photos the guide and the cards show', () async {
    fakes.answerEverything(
      guide: [NannyFixtures.nappies.copyWith(photoId: 'photo-shelf')],
      cards: [NannyFixtures.kidCard.copyWith(photoId: 'photo-kid')],
    );
    await pumpEventQueue();
    expect(fakes.photos.reads.toSet(), {'photo-shelf', 'photo-kid'});
  });

  test(
    'reads a child’s medication only when the medical grant opens it',
    () async {
      fakes.answerAFullHub();
      await pumpEventQueue();
      expect(fakes.family.healthWatched, [Fixtures.kidMemberId]);
      fakes.family.emitHealth(
        const MemberHealth(
          id: Fixtures.kidMemberId,
          medications: {'m1': FamilyFixtures.inhaler},
        ),
      );
      await pumpEventQueue();
      expect(
        controller.healthOf(Fixtures.kidMemberId),
        isA<AsyncData<MemberHealth>>(),
      );
    },
  );

  test(
    'a carer the grant keeps out asks for neither profiles nor medication',
    () async {
      controller.dispose();
      fakes.family.profilesAskedFor.clear();
      fakes.family.healthWatched.clear();
      controller = build(NannyFixtures.carerWithoutProfilesView());
      fakes.answerAFullHub();
      await pumpEventQueue();
      expect(fakes.family.profilesAskedFor, isEmpty);
      expect(fakes.family.healthWatched, isEmpty);
      expect(loaded().children.single.food, isNull);
      expect(controller.healthOf(Fixtures.kidMemberId), isNull);
    },
  );

  test('starts the viewer’s own shift, stamped as theirs', () async {
    fakes.answerAFullHub();
    await pumpEventQueue();
    expect(await controller.startShift(), 'shift-new');
    expect(fakes.shifts.writes.single.$2, {
      'carerMemberId': NannyFixtures.nomsaMemberId,
      'startedBy': NannyFixtures.nomsaMemberId,
    });
  });

  test('a refused start answers null and keeps the reason', () async {
    fakes.shifts.failWritesWith = const PermissionDeniedFailure();
    expect(await controller.startShift(), isNull);
    expect(controller.actionFailure, isA<PermissionDeniedFailure>());
  });

  test('offers family every grown-up but themselves to start a shift for', () {
    controller.dispose();
    controller = build(NannyFixtures.parentView());
    expect(controller.carersToStartFor.map((member) => member.id), [
      NannyFixtures.nomsaMemberId,
      Fixtures.thandiMemberId,
    ]);
  });

  test('a camera that will not open is a banner, and no photo', () async {
    fakes.picker.failWith = const NannyHubFailure(
      NannyHubProblem.cameraUnavailable,
    );
    expect(await controller.pickPhoto(PhotoSource.camera), isNull);
    expect(
      controller.actionFailure,
      const TypeMatcher<NannyHubFailure>().having(
        (failure) => failure.problem,
        'problem',
        NannyHubProblem.cameraUnavailable,
      ),
    );
    fakes.picker.failWith = null;
    fakes.picker.next = Uint8List.fromList([1]);
    expect(await controller.pickPhoto(PhotoSource.library), [1]);
  });

  test('a call the phone will not place says so', () async {
    fakes.opener.opens = false;
    await controller.call(Uri.parse('tel:10177'));
    expect(controller.actionFailure, isA<NannyHubFailure>());
  });

  test(
    'a changed grant starts the reads again; a new member only re-joins',
    () async {
      fakes.answerAFullHub();
      await pumpEventQueue();
      controller.followHousehold(NannyFixtures.carerView());
      expect(controller.view, isA<AsyncData<NannyHubView>>());

      controller.followHousehold(NannyFixtures.lookOnlyCarerView());
      await pumpEventQueue();
      expect(controller.view, isA<AsyncLoading<NannyHubView>>());
      expect(controller.access.canEdit, isFalse);
    },
  );
}
