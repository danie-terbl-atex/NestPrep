import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/avatars/data/avatar_photo_store.dart';
import 'package:nestprep/features/avatars/model/avatar_base.dart';
import 'package:nestprep/features/avatars/model/avatar_catalogue.g.dart';
import 'package:nestprep/features/avatars/model/avatar_place.dart';
import 'package:nestprep/features/avatars/model/member_look.dart';
import 'package:nestprep/features/avatars/ui/member_avatar.dart';
import 'package:nestprep/features/household/model/birthday.dart';
import 'package:nestprep/features/household/model/member.dart';
import 'package:nestprep/shared/flags/feature_flag.dart';
import 'package:nestprep/shared/flags/feature_flags_controller.dart';
import 'package:nestprep/shared/time/calendar_date.dart';
import 'package:provider/provider.dart';

import '../../../support/fake_avatars.dart';
import '../../../support/fake_feature_flag_source.dart';
import '../../../support/household_fixtures.dart';

void main() {
  final ordinaryDay = AvatarPlace(
    householdId: Fixtures.householdId,
    today: CalendarDate(2026, 11, 12),
    hemisphere: AvatarHemisphere.south,
  );
  const pip = MemberLook(base: PresetBase('pip'), stage: 2);

  Future<void> pump(
    WidgetTester tester,
    Member member, {
    bool avatarsOn = true,
    AvatarPlace? place,
    AvatarPhotoStore? photos,
  }) async {
    final flags = featureFlagsProvider(defaultOn: avatarsOn);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          flags,
          Provider<AvatarPlace?>.value(value: place ?? ordinaryDay),
          Provider<AvatarPhotoStore>.value(
            value: photos ?? FakeAvatarPhotoStore(),
          ),
        ],
        child: MaterialApp(
          theme: nestThemeData(NestTheme.light()),
          home: Scaffold(
            body: Center(child: MemberAvatar(member: member)),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  NestAvatar avatar(WidgetTester tester) =>
      tester.widget<NestAvatar>(find.byType(NestAvatar));

  String? assetOf(ImageProvider? image) => switch (image) {
    AssetImage(:final assetName) => assetName,
    _ => null,
  };

  testWidgets('no look is the initial, exactly as today', (tester) async {
    await pump(tester, Fixtures.kid);
    expect(avatar(tester).picture, isNull);
    expect(avatar(tester).layers, isEmpty);
  });

  testWidgets('with avatars switched off a look is still the initial', (
    tester,
  ) async {
    await pump(tester, Fixtures.kid.copyWith(look: pip), avatarsOn: false);
    expect(avatar(tester).picture, isNull);
    expect(avatar(tester).layers, isEmpty);
  });

  testWidgets('a Nestling is its asset at the look\'s stage', (tester) async {
    await pump(tester, Fixtures.kid.copyWith(look: pip));
    expect(
      assetOf(avatar(tester).picture),
      'assets/avatars/nestling-pip-2.webp',
    );
    expect(avatar(tester).name, Fixtures.kid.displayName);
  });

  testWidgets('a Nestling the build does not know is the initial', (
    tester,
  ) async {
    await pump(
      tester,
      Fixtures.kid.copyWith(
        look: const MemberLook(base: PresetBase('not-a-bird'), stage: 1),
      ),
    );
    expect(avatar(tester).picture, isNull);
  });

  testWidgets('what is worn becomes a layer; an unknown accessory is skipped', (
    tester,
  ) async {
    await pump(
      tester,
      Fixtures.kid.copyWith(
        look: pip.copyWith(
          wear: const {
            AvatarSlot.top: 'acc-crown',
            AvatarSlot.badge: 'acc-not-in-this-build',
          },
        ),
      ),
    );
    final layers = avatar(tester).layers;
    expect(layers.map((layer) => layer.slot), [NestAvatarSlot.top]);
    expect(assetOf(layers.single.image), 'assets/avatars/acc-crown.webp');
  });

  testWidgets('a birthday puts the birthday hat on, over a crown', (
    tester,
  ) async {
    await pump(
      tester,
      Fixtures.kid.copyWith(
        birthday: Birthday(month: 11, day: 12),
        look: pip.copyWith(wear: const {AvatarSlot.top: 'acc-crown'}),
      ),
    );
    expect(
      assetOf(avatar(tester).layers.single.image),
      'assets/avatars/moment-birthday-hat.webp',
    );
  });

  testWidgets('the festive hat on Christmas, where nothing is worn on top', (
    tester,
  ) async {
    await pump(
      tester,
      Fixtures.kid.copyWith(look: pip),
      place: AvatarPlace(
        householdId: Fixtures.householdId,
        today: CalendarDate(2026, 12, 25),
        hemisphere: AvatarHemisphere.south,
      ),
    );
    expect(
      assetOf(avatar(tester).layers.single.image),
      'assets/avatars/moment-festive-hat.webp',
    );
  });

  testWidgets('a photo is drawn once its bytes are here, the initial until', (
    tester,
  ) async {
    const hash = '0123456789abcdef0123456789abcdef';
    final photos = FakeAvatarPhotoStore();
    await pump(
      tester,
      Fixtures.kid.copyWith(look: const MemberLook(base: ImageBase(hash))),
      photos: photos,
    );
    expect(avatar(tester).picture, isNull);

    photos.stored[hash] = Uint8List.fromList([1, 2, 3]);
    await pump(
      tester,
      Fixtures.kid.copyWith(
        look: const MemberLook(base: ImageBase(hash), stage: 1),
      ),
      photos: photos,
    );
    expect(avatar(tester).picture, isA<MemoryImage>());
  });

  testWidgets('glasses are only worn on a Nestling with a face anchor', (
    tester,
  ) async {
    await pump(
      tester,
      Fixtures.kid.copyWith(
        look: const MemberLook(
          base: ImageBase('0123456789abcdef0123456789abcdef'),
          wear: {AvatarSlot.face: 'acc-round-glasses'},
        ),
      ),
    );
    expect(avatar(tester).layers, isEmpty);
  });

  testWidgets('glasses sit on the Nestling\'s own eyes, 1.6 eye spans wide', (
    tester,
  ) async {
    await pump(
      tester,
      Fixtures.kid.copyWith(
        look: pip.copyWith(wear: const {AvatarSlot.face: 'acc-round-glasses'}),
      ),
    );
    final face = avatarNestlingFaces['nestling-pip-2']!;
    final glasses = avatar(tester).layers.single;
    expect(glasses.slot, NestAvatarSlot.face);
    expect(glasses.centre, Offset(face.x, face.y));
    expect(glasses.width, closeTo(face.w * 1.6, 0.0001));
  });

  testWidgets('every Nestling picture has a face anchor', (tester) async {
    for (final nestling in avatarNestlings) {
      for (final stage in avatarNestlingStages) {
        expect(
          avatarNestlingFaces,
          contains(nestlingAssetId(nestling.name, stage)),
        );
      }
    }
  });

  testWidgets('a member who chose their initial keeps it, with what they '
      'wear and the birthday hat', (tester) async {
    await pump(
      tester,
      Fixtures.kid.copyWith(
        birthday: Birthday(month: 11, day: 12),
        look: const MemberLook(wear: {AvatarSlot.badge: 'acc-football'}),
      ),
    );
    expect(avatar(tester).picture, isNull);
    expect(
      find.text(Fixtures.kid.displayName[0].toUpperCase()),
      findsOneWidget,
    );
    expect(
      {for (final layer in avatar(tester).layers) assetOf(layer.image)},
      {
        'assets/avatars/moment-birthday-hat.webp',
        'assets/avatars/acc-football.webp',
      },
    );
  });

  testWidgets('with no look a birthday changes nothing', (tester) async {
    await pump(
      tester,
      Fixtures.kid.copyWith(birthday: Birthday(month: 11, day: 12)),
    );
    expect(avatar(tester).picture, isNull);
    expect(avatar(tester).layers, isEmpty);
  });

  testWidgets('the feature flag field is avatars', (tester) async {
    expect(FeatureFlag.avatars.field, 'avatars');
    expect(FeatureFlag.avatarCreations.field, 'avatarCreations');
    expect(FeatureFlagsController, isNotNull);
  });
}
