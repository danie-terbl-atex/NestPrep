import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/avatars/model/avatar_buddy.dart';
import 'package:nestprep/features/avatars/model/avatar_catalogue.g.dart';
import 'package:nestprep/features/avatars/model/avatar_creation.dart';
import 'package:nestprep/features/avatars/state/avatar_creation_controller.dart';
import 'package:nestprep/features/avatars/state/creation_step.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/fake_avatars.dart';
import '../../../support/household_fixtures.dart';

void main() {
  late FakeAvatarRepository avatars;
  late FakeAvatarPhotoStore photos;
  final jpeg = Uint8List.fromList(List.filled(64, 7));
  const hash = '0123456789abcdef0123456789abcdef';
  const dragon = AvatarBuddy({
    AvatarBuddyKind.creature: 'dragon',
    AvatarBuddyKind.colour: 'purple',
    AvatarBuddyKind.loves: 'pancakes',
    AvatarBuddyKind.wears: 'cape',
    AvatarBuddyKind.power: 'flying',
  });

  setUp(() {
    avatars = FakeAvatarRepository();
    photos = FakeAvatarPhotoStore();
  });

  tearDown(() => avatars.close());

  AvatarCreationController open({
    String memberId = Fixtures.kidMemberId,
    Duration wait = const Duration(seconds: 120),
  }) {
    final controller = AvatarCreationController(
      avatarRepository: avatars,
      photoStore: photos,
      householdId: Fixtures.householdId,
      memberId: memberId,
      viewerMemberId: Fixtures.samMemberId,
      viewerUid: Fixtures.samUid,
      wait: wait,
    );
    addTearDown(controller.dispose);
    return controller;
  }

  AvatarCreation settled(
    String id, {
    CreationStatus? status,
    CreationRefusal? reason,
    String? imageHash,
    int? left,
    CreationRecipe recipe = CreationRecipe.drawing,
  }) => AvatarCreation(
    id: id,
    memberId: Fixtures.kidMemberId,
    recipe: recipe,
    status: status,
    reason: reason,
    imageHash: imageHash,
    left: left,
  );

  Future<void> tick() => Future<void>.delayed(Duration.zero);

  test('a drawing goes up as the reference, then the request names it, and '
      'the status walks from checking to drawing to ready', () async {
    final controller = open();
    await controller.makeFromPicture(
      recipe: CreationRecipe.drawing,
      jpeg: jpeg,
      style: CreationStyle.clay,
    );
    final request = avatars.requested.single;
    final reference = photos.references.single;
    expect(reference.inboxId, request.id);
    expect(reference.memberId, Fixtures.kidMemberId);
    expect(reference.uploaderUid, Fixtures.samUid);
    expect(request.inboxId, request.id);
    expect(request.recipe, CreationRecipe.drawing);
    expect(request.style, CreationStyle.clay);
    expect(request.by, Fixtures.samMemberId);
    expect(request.buddy, isNull);
    expect(request.extra, isNull);
    expect(controller.step, isA<CreationWaiting>());

    avatars.settleCreation(
      settled(request.id, status: CreationStatus.checking),
    );
    await tick();
    expect((controller.step as CreationWaiting).isDrawing, isFalse);
    avatars.settleCreation(settled(request.id, status: CreationStatus.drawing));
    await tick();
    expect((controller.step as CreationWaiting).isDrawing, isTrue);
    avatars.settleCreation(
      settled(
        request.id,
        status: CreationStatus.ready,
        imageHash: hash,
        left: 11,
      ),
    );
    await tick();
    expect((controller.step as CreationReady).imageHash, hash);
  });

  test(
    'a buddy sends its chips and a trimmed extra, never a reference',
    () async {
      final controller = open();
      await controller.makeBuddy(dragon, extra: '  has spotty socks  ');
      final request = avatars.requested.single;
      expect(photos.references, isEmpty);
      expect(request.recipe, CreationRecipe.buddy);
      expect(request.inboxId, isNull);
      expect(request.buddy, dragon);
      expect(request.extra, 'has spotty socks');
      expect(dragon.toFirestore(), {
        'creature': 'dragon',
        'colour': 'purple',
        'loves': 'pancakes',
        'wears': 'cape',
        'power': 'flying',
      });

      avatars.settleCreation(
        settled(
          request.id,
          recipe: CreationRecipe.buddy,
          status: CreationStatus.ready,
          imageHash: hash,
        ),
      );
      await tick();
      expect((controller.step as CreationReady).buddy, dragon);
    },
  );

  test('an empty extra is left out, and a long one is cut to 60', () async {
    final controller = open();
    await controller.makeBuddy(dragon, extra: '   ');
    expect(avatars.requested.single.extra, isNull);
    await controller.startOver();
    await controller.makeBuddy(dragon, extra: 'x' * 80);
    expect(avatars.requested.last.extra, hasLength(60));
  });

  test('a portrait carries no style and no reference', () async {
    final controller = open(memberId: Fixtures.samMemberId);
    await controller.makePortrait();
    final request = avatars.requested.single;
    expect(request.recipe, CreationRecipe.portrait);
    expect(request.memberId, Fixtures.samMemberId);
    expect(request.style, isNull);
    expect(request.inboxId, isNull);
  });

  for (final reason in CreationRefusal.values) {
    test('a refusal for ${reason.name} settles with its reason', () async {
      final controller = open();
      await controller.makeFromPicture(recipe: CreationRecipe.pet, jpeg: jpeg);
      avatars.settleCreation(
        settled(
          avatars.requested.single.id,
          status: reason == CreationRefusal.unavailable
              ? CreationStatus.failed
              : CreationStatus.refused,
          reason: reason,
          left: 0,
        ),
      );
      await tick();
      final step = controller.step as CreationRefused;
      expect(step.reason, reason);
      expect(step.recipe, CreationRecipe.pet);
      expect(step.left, 0);
    });
  }

  test('a failure with no reason reads as unavailable', () async {
    final controller = open();
    await controller.makeBuddy(dragon);
    avatars.settleCreation(
      settled(avatars.requested.single.id, status: CreationStatus.failed),
    );
    await tick();
    expect(
      (controller.step as CreationRefused).reason,
      CreationRefusal.unavailable,
    );
  });

  test('a slow hatch says so, and still lands if it finishes late', () async {
    final controller = open(wait: const Duration(milliseconds: 20));
    await controller.makeBuddy(dragon);
    await Future<void>.delayed(const Duration(milliseconds: 40));
    expect(controller.step, isA<CreationTooSlow>());
    expect(controller.isBusy, isFalse);

    avatars.settleCreation(
      settled(
        avatars.requested.single.id,
        status: CreationStatus.ready,
        imageHash: hash,
      ),
    );
    await tick();
    expect(controller.step, isA<CreationReady>());
  });

  test('a request that never reaches the server ends in too slow, not a '
      'spinner for ever', () async {
    avatars.creationsNeverLand = true;
    final controller = open(wait: const Duration(milliseconds: 20));
    await controller.makeBuddy(dragon);
    expect(controller.step, isA<CreationTooSlow>());

    avatars.settleCreation(
      settled(
        'creation-1-abcdefgh',
        status: CreationStatus.ready,
        imageHash: hash,
      ),
    );
    await tick();
    expect(controller.step, isA<CreationReady>());
  });

  test('an upload that fails goes back to choosing and says why', () async {
    photos.failReferencesWith = const AvatarFailure(
      AvatarProblem.photoTooLarge,
    );
    final controller = open();
    await controller.makeFromPicture(
      recipe: CreationRecipe.drawing,
      jpeg: jpeg,
    );
    expect(controller.step, isA<CreationComposing>());
    expect(controller.actionFailure, isA<AvatarFailure>());
    expect(avatars.requested, isEmpty);
  });

  test(
    'after starting over, a late answer to the old request is ignored',
    () async {
      final controller = open();
      await controller.makeBuddy(dragon);
      final id = avatars.requested.single.id;
      await controller.startOver();
      avatars.settleCreation(
        settled(id, status: CreationStatus.ready, imageHash: hash),
      );
      await tick();
      expect(controller.step, isA<CreationComposing>());
    },
  );

  test('a second tap while one is hatching asks for nothing more', () async {
    final controller = open();
    await controller.makeBuddy(dragon);
    await controller.makeBuddy(dragon);
    expect(avatars.requested, hasLength(1));
  });

  test('the household’s recent creations follow the stream', () async {
    final controller = open();
    await tick();
    expect(controller.recent, isEmpty);
    avatars.emitRecent([settled('c1', left: 4)]);
    await tick();
    expect(controller.recent.single.left, 4);
  });
}
