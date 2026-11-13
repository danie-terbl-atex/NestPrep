import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nestprep/features/avatars/data/avatar_photo_picker.dart';
import 'package:nestprep/features/avatars/data/avatar_photo_store.dart';
import 'package:nestprep/features/avatars/data/avatar_repository.dart';
import 'package:nestprep/features/avatars/model/avatar_catalogue.g.dart';
import 'package:nestprep/features/avatars/model/avatar_place.dart';
import 'package:nestprep/features/avatars/model/member_avatar_record.dart';
import 'package:nestprep/features/avatars/state/avatar_creation_controller.dart';
import 'package:nestprep/features/avatars/state/avatar_keepsakes_controller.dart';
import 'package:nestprep/features/avatars/state/avatar_studio_controller.dart';
import 'package:nestprep/features/avatars/state/creation_reference.dart';
import 'package:nestprep/features/avatars/ui/avatar_studio_screen.dart';
import 'package:nestprep/features/avatars/ui/avatar_studio_tab.dart';
import 'package:nestprep/features/chore_points/model/point_balance.dart';
import 'package:nestprep/features/household/model/household_view.dart';
import 'package:nestprep/features/household/model/member.dart';
import 'package:nestprep/features/subscriptions/model/entitlement.dart';
import 'package:nestprep/shared/photos/compressed_photo.dart';
import 'package:nestprep/shared/photos/photo_compressor.dart';
import 'package:nestprep/shared/time/calendar_date.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'fake_avatars.dart';
import 'fake_chore_points.dart';
import 'fake_household.dart';
import 'household_fixtures.dart';
import 'pump_screen.dart';
import 'pump_subscriptions.dart';

final class PassThroughCompressor implements PhotoCompressor {
  const PassThroughCompressor();

  @override
  Future<CompressedPhoto> compress(Uint8List original) async =>
      CompressedPhoto(bytes: original, width: 64, height: 48);
}

Uint8List aPhoto() => Uint8List.fromList(
  img.encodeJpg(
    img.Image(width: 64, height: 48)..clear(img.ColorRgb8(200, 120, 90)),
  ),
);

final class StudioRig {
  StudioRig({
    required this.member,
    MemberAvatarRecord record = MemberAvatarRecord.none,
    this.viewerMemberId = Fixtures.samMemberId,
    Uint8List? photo,
    this.creations = true,
    Entitlement entitlement = Entitlement.free,
    Duration creationWait = const Duration(seconds: 120),
  }) : avatars = FakeAvatarRepository(record),
       picker = FakeAvatarPhotoPicker(photo),
       subscriptions = SubscriptionHarness(entitlement: entitlement) {
    controller = AvatarStudioController(
      householdRepository: households,
      avatarRepository: avatars,
      pointsRepository: points,
      photoStore: photos,
      householdId: Fixtures.householdId,
      memberId: member.id,
      viewerMemberId: viewerMemberId,
      viewerUid: Fixtures.samUid,
    );
    creation = AvatarCreationController(
      avatarRepository: avatars,
      photoStore: photos,
      householdId: Fixtures.householdId,
      memberId: member.id,
      viewerMemberId: viewerMemberId,
      viewerUid: Fixtures.samUid,
      wait: creationWait,
    );
    keepsakes = AvatarKeepsakesController(
      avatarRepository: avatars,
      householdId: Fixtures.householdId,
      memberId: member.id,
      viewerMemberId: viewerMemberId,
    );
  }

  final Member member;
  final String viewerMemberId;
  final bool creations;
  final households = FakeHouseholdRepository();
  final FakeAvatarRepository avatars;
  final points = FakePointsRepository();
  final photos = FakeAvatarPhotoStore();
  final FakeAvatarPhotoPicker picker;
  final SubscriptionHarness subscriptions;
  late final AvatarStudioController controller;
  late final AvatarCreationController creation;
  late final AvatarKeepsakesController keepsakes;

  static final place = AvatarPlace(
    householdId: Fixtures.householdId,
    today: CalendarDate(2026, 11, 12),
    hemisphere: AvatarHemisphere.south,
  );

  HouseholdView viewFor({required bool asFamily, required bool creationsOn}) {
    final household = Fixtures.household().copyWith(
      avatarCreationsOn: creationsOn,
    );
    return asFamily
        ? HouseholdView(
            household: household,
            members: [Fixtures.sam, Fixtures.thandi, Fixtures.kid],
            viewerUid: Fixtures.samUid,
          )
        : HouseholdView(
            household: household.copyWith(
              profiles: {Fixtures.thandiUid: Fixtures.thandiMemberId},
            ),
            members: [Fixtures.sam, Fixtures.thandi, Fixtures.kid],
            viewerUid: Fixtures.thandiUid,
          );
  }

  List<SingleChildWidget> get providers => [
    ChangeNotifierProvider<AvatarStudioController>.value(value: controller),
    if (creations)
      ChangeNotifierProvider<AvatarCreationController>.value(value: creation),
    ChangeNotifierProvider<AvatarKeepsakesController>.value(value: keepsakes),
    Provider<AvatarRepository>.value(value: avatars),
    Provider<AvatarPhotoPicker>.value(value: picker),
    Provider<AvatarPhotoStore>.value(value: photos),
    Provider<AvatarPlace?>.value(value: place),
    Provider<CreationReference?>.value(
      value: const CreationReference(compressor: PassThroughCompressor()),
    ),
    ...subscriptions.providers,
  ];

  Future<void> pump(
    WidgetTester tester, {
    AvatarStudioTab tab = AvatarStudioTab.nestlings,
    Brightness brightness = Brightness.light,
    double textScale = 1,
    bool shopIsOpen = true,
    bool creationsOn = true,
    bool asFamily = true,
    PointBalance? balance,
  }) async {
    await pumpScreen(
      tester,
      AvatarStudioScreen(initialTab: tab),
      providers: providers,
      view: viewFor(asFamily: asFamily, creationsOn: creationsOn),
      brightness: brightness,
      textScale: textScale,
    );
    households
      ..emitMember(member)
      ..emitHousehold(
        Fixtures.household().copyWith(
          avatarShop: shopIsOpen,
          avatarCreationsOn: creationsOn,
        ),
      );
    if (balance != null) {
      await tester.pump();
      points.emitBalance(balance);
    }
    await tester.pumpAndSettle();
  }

  Future<void> close() async {
    controller.dispose();
    creation.dispose();
    keepsakes.dispose();
    await households.close();
    await avatars.close();
  }
}
