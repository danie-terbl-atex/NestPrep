import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/avatars/model/avatar_base.dart';
import 'package:nestprep/features/avatars/model/avatar_catalogue.g.dart';
import 'package:nestprep/features/avatars/model/avatar_choice.dart';
import 'package:nestprep/features/avatars/model/avatar_library.dart';
import 'package:nestprep/features/avatars/model/avatar_purchase.dart';
import 'package:nestprep/features/avatars/model/avatar_stage.dart';
import 'package:nestprep/features/avatars/model/avatar_studio.dart';
import 'package:nestprep/features/avatars/model/member_avatar_record.dart';
import 'package:nestprep/features/avatars/state/avatar_studio_controller.dart';
import 'package:nestprep/features/chore_points/model/point_balance.dart';
import 'package:nestprep/features/household/model/member.dart';
import 'package:nestprep/shared/async/async_state.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/fake_avatars.dart';
import '../../../support/fake_chore_points.dart';
import '../../../support/fake_household.dart';
import '../../../support/household_fixtures.dart';

void main() {
  late FakeHouseholdRepository households;
  late FakeAvatarRepository avatars;
  late FakePointsRepository points;
  late FakeAvatarPhotoStore photos;

  final crown = AvatarLibrary.bundled.accessory('acc-crown')!;

  setUp(() {
    households = FakeHouseholdRepository();
    avatars = FakeAvatarRepository();
    points = FakePointsRepository();
    photos = FakeAvatarPhotoStore();
  });

  tearDown(() async {
    await households.close();
    await avatars.close();
  });

  Future<AvatarStudioController> open(
    Member member, {
    Duration purchaseWait = const Duration(seconds: 20),
  }) async {
    final controller = AvatarStudioController(
      purchaseWait: purchaseWait,
      householdRepository: households,
      avatarRepository: avatars,
      pointsRepository: points,
      photoStore: photos,
      householdId: Fixtures.householdId,
      memberId: member.id,
      viewerMemberId: Fixtures.samMemberId,
      viewerUid: Fixtures.samUid,
    );
    addTearDown(controller.dispose);
    await Future<void>.delayed(Duration.zero);
    households
      ..emitMember(member)
      ..emitHousehold(Fixtures.household());
    await Future<void>.delayed(Duration.zero);
    return controller;
  }

  AvatarStudio studioOf(AvatarStudioController controller) =>
      (controller.studio as AsyncData<AvatarStudio>).value;

  test('a grown-up picks a Nestling, fully grown unless they choose', () async {
    final controller = await open(Fixtures.sam);
    await controller.pickNestling('pip');
    expect(avatars.chosen.single.choice.base, const PresetBase('pip'));
    expect(avatars.chosen.single.choice.stage, AvatarStage.flyer);
    expect(avatars.chosen.single.by, Fixtures.samMemberId);
    expect(studioOf(controller).nestlingName(), 'pip');

    await controller.pickStage(AvatarStage.hatchling);
    expect(avatars.chosen.last.choice.stage, AvatarStage.hatchling);
    expect(studioOf(controller).stage, AvatarStage.hatchling);
  });

  test('a child\'s stage comes from their stars, never their choice', () async {
    final controller = await open(Fixtures.kid);
    points.emitBalance(
      const PointBalance(id: Fixtures.kidMemberId, earned: 4, bestStreak: 3),
    );
    await Future<void>.delayed(Duration.zero);
    await controller.pickNestling('olive');
    expect(avatars.chosen.single.choice.stage, isNull);
    expect(studioOf(controller).stage, AvatarStage.fledgling);
    expect(studioOf(controller).progress.toGo, 4);

    await controller.pickStage(AvatarStage.flyer);
    expect(avatars.chosen.last.choice.stage, isNull);
  });

  test('wearing and taking off, and back to the initial', () async {
    final controller = await open(Fixtures.sam);
    await controller.wear(AvatarSlot.top, 'acc-party-hat');
    expect(avatars.chosen.last.choice.wear, {AvatarSlot.top: 'acc-party-hat'});
    await controller.wear(AvatarSlot.top, null);
    expect(avatars.chosen.last.choice.wear, isEmpty);
    await controller.useInitial();
    expect(avatars.chosen.last.choice.base, const InitialBase());
  });

  test('a refused write puts the choice back and says why', () async {
    final controller = await open(Fixtures.sam);
    avatars.failWritesWith = const PermissionDeniedFailure();
    await controller.pickNestling('pip');
    expect(controller.actionFailure, isA<PermissionDeniedFailure>());
    expect(studioOf(controller).nestlingName(), isNull);
  });

  test(
    'a photo is uploaded under its hash, then offered with the choice',
    () async {
      final controller = await open(Fixtures.sam);
      final jpeg = Uint8List.fromList(List.generate(64, (i) => i));
      await controller.savePhoto(jpeg);
      final hash = AvatarStudioController.hashOf(jpeg);
      expect(hash, matches(RegExp(r'^[0-9a-f]{32}$')));
      expect(photos.uploaded.single, (
        hash: hash,
        uploaderUid: Fixtures.samUid,
      ));
      expect(avatars.offered.single.hash, hash);
      expect(avatars.offered.single.choice, const AvatarChoice());
      expect(studioOf(controller).preview.base, ImageBase(hash));

      avatars.emit(
        MemberAvatarRecord(
          choice: AvatarChoice(base: ImageBase(hash)),
          ownedImages: [hash],
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(studioOf(controller).preview.base, ImageBase(hash));
    },
  );

  test('a purchase that comes back owned is worn, and celebrated', () async {
    final controller = await open(Fixtures.kid);
    await controller.buy(crown);
    expect(controller.isBuying(crown.id), isTrue);
    expect(avatars.bought.single.accessoryId, crown.id);

    avatars.settle(
      AvatarPurchase(
        id: 'purchase-1',
        memberId: Fixtures.kidMemberId,
        accessoryId: crown.id,
        status: PurchaseStatus.owned,
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(controller.isBuying(crown.id), isFalse);
    expect(controller.outcome?.isOwned, isTrue);
    expect(avatars.chosen.last.choice.wear, {AvatarSlot.top: crown.id});
  });

  test('a refused purchase keeps its reason, and wears nothing', () async {
    final controller = await open(Fixtures.kid);
    await controller.buy(crown);
    avatars.settle(
      AvatarPurchase(
        id: 'purchase-1',
        memberId: Fixtures.kidMemberId,
        accessoryId: crown.id,
        status: PurchaseStatus.refused,
        reason: PurchaseRefusal.notEnoughStars,
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(controller.outcome?.isOwned, isFalse);
    expect(controller.outcome?.reason, PurchaseRefusal.notEnoughStars);
    expect(avatars.chosen, isEmpty);
    controller.dismissOutcome();
    expect(controller.outcome, isNull);
  });

  test('a purchase nobody answers stops waiting and says so', () async {
    final controller = await open(
      Fixtures.kid,
      purchaseWait: const Duration(milliseconds: 20),
    );
    await controller.buy(crown);
    await Future<void>.delayed(const Duration(milliseconds: 40));
    expect(controller.isBuying(crown.id), isFalse);
    expect(controller.outcome?.isTooSlow, isTrue);
    expect(controller.outcome?.isOwned, isFalse);
    avatars.settle(
      AvatarPurchase(
        id: 'purchase-1',
        memberId: Fixtures.kidMemberId,
        accessoryId: crown.id,
        status: PurchaseStatus.owned,
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(avatars.chosen, isEmpty);
  });

  test('a purchase that never leaves the phone stops waiting too', () async {
    final controller = await open(
      Fixtures.kid,
      purchaseWait: const Duration(milliseconds: 20),
    );
    avatars.purchasesNeverLand = true;
    await controller.buy(crown);
    expect(controller.isBuying(crown.id), isFalse);
    expect(controller.outcome?.isTooSlow, isTrue);
    expect(controller.actionFailure, isNull);
  });

  test(
    'the shop follows the household switch, and is a child\'s only',
    () async {
      final kid = await open(Fixtures.kid);
      expect(studioOf(kid).showsShop, isTrue);
      households.emitHousehold(
        Fixtures.household().copyWith(avatarShop: false),
      );
      await Future<void>.delayed(Duration.zero);
      expect(studioOf(kid).showsShop, isFalse);

      final sam = await open(Fixtures.sam);
      expect(studioOf(sam).showsShop, isFalse);
    },
  );

  test('a member who is gone is not found', () async {
    final controller = AvatarStudioController(
      householdRepository: households,
      avatarRepository: avatars,
      pointsRepository: points,
      photoStore: photos,
      householdId: Fixtures.householdId,
      memberId: 'm-gone',
      viewerMemberId: Fixtures.samMemberId,
      viewerUid: Fixtures.samUid,
    );
    addTearDown(controller.dispose);
    await Future<void>.delayed(Duration.zero);
    households.emitMember(null);
    await Future<void>.delayed(Duration.zero);
    expect(controller.studio, isA<AsyncFailure<AvatarStudio>>());
  });
}
