import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';

import '../../support/pump_kit.dart';

void main() {
  const crown = AssetImage('assets/avatars/acc-crown.webp');
  const pip = AssetImage('assets/avatars/nestling-pip-2.webp');

  for (final brightness in bothThemes) {
    group('in ${brightness.name}', () {
      testWidgets('with no picture it draws the initial exactly as before', (
        tester,
      ) async {
        final semantics = tester.ensureSemantics();
        await pumpKit(
          tester,
          const NestAvatar(name: 'mia', color: MemberColor.coral),
          brightness: brightness,
        );
        final nest = brightness == Brightness.dark
            ? NestTheme.dark()
            : NestTheme.light();
        final inside = find.byType(NestAvatar);
        expect(
          find.descendant(of: inside, matching: find.byType(Image)),
          findsNothing,
        );
        expect(
          find.descendant(of: inside, matching: find.byType(Stack)),
          findsNothing,
        );
        expect(find.text('M'), findsOneWidget);
        final box = tester.widget<DecoratedBox>(
          find.descendant(
            of: find.byType(NestAvatar),
            matching: find.byType(DecoratedBox),
          ),
        );
        final decoration = box.decoration as BoxDecoration;
        expect(decoration.color, nest.members.of(MemberColor.coral).fill);
        expect(decoration.shape, BoxShape.circle);
        expect(
          tester.getSize(find.byType(NestAvatar)),
          const Size.square(NestSize.avatarMedium),
        );
        expect(find.bySemanticsLabel('mia'), findsOneWidget);
        semantics.dispose();
      });

      testWidgets('a picture sits on the light fill, in a box of the same '
          'size, and keeps the name for a screen reader', (tester) async {
        final semantics = tester.ensureSemantics();
        await pumpKit(
          tester,
          const NestAvatar(
            name: 'Mia',
            color: MemberColor.coral,
            picture: pip,
            layers: [NestAvatarLayer(slot: NestAvatarSlot.top, image: crown)],
          ),
          brightness: brightness,
        );
        expect(
          tester.getSize(find.byType(NestAvatar)),
          const Size.square(NestSize.avatarMedium),
        );
        expect(find.byType(Image), findsNWidgets(2));
        final fill = tester
            .widgetList<DecoratedBox>(
              find.descendant(
                of: find.byType(NestAvatar),
                matching: find.byType(DecoratedBox),
              ),
            )
            .map((box) => (box.decoration as BoxDecoration).color)
            .first;
        expect(fill, NestMemberPalette.light.of(MemberColor.coral).fill);
        expect(find.bySemanticsLabel('Mia'), findsOneWidget);
        semantics.dispose();
      });
    });
  }

  testWidgets('layers paint in ring, face, top, badge order', (tester) async {
    await pumpKit(
      tester,
      const NestAvatar(
        name: 'Mia',
        color: MemberColor.coral,
        picture: pip,
        layers: [
          NestAvatarLayer(slot: NestAvatarSlot.badge, image: crown),
          NestAvatarLayer(slot: NestAvatarSlot.top, image: pip),
          NestAvatarLayer(slot: NestAvatarSlot.ring, image: crown),
        ],
      ),
    );
    final images = tester.widgetList<Image>(find.byType(Image)).toList();
    final sides = [
      for (final image in images.skip(1)) (image.image as ResizeImage).width!,
    ];
    final ring = NestAvatar.layerBox(
      const NestAvatarLayer(slot: NestAvatarSlot.ring, image: crown),
      NestSize.avatarMedium,
    ).width;
    final top = NestAvatar.layerBox(
      const NestAvatarLayer(slot: NestAvatarSlot.top, image: crown),
      NestSize.avatarMedium,
    ).width;
    final pixels = MediaQuery.devicePixelRatioOf(
      tester.element(find.byType(NestAvatar)),
    );
    expect(sides.first, (ring * pixels).ceil());
    expect(sides[1], (top * pixels).ceil());
  });

  test('a top layer rises above the circle and a badge spills past its '
      'corner, by the advertised share', () {
    const size = 100.0;
    final top = NestAvatar.layerBox(
      const NestAvatarLayer(slot: NestAvatarSlot.top, image: crown),
      size,
    );
    final badge = NestAvatar.layerBox(
      const NestAvatarLayer(slot: NestAvatarSlot.badge, image: crown),
      size,
    );
    expect(top.top, closeTo(-size * NestAvatar.topOverhang, 0.001));
    expect(top.center.dx, size / 2);
    expect(badge.right, closeTo(size * (1 + NestAvatar.badgeOverhang), 0.001));
    expect(badge.bottom, closeTo(size * (1 + NestAvatar.badgeOverhang), 0.001));
  });

  test('an anchored layer is centred where it is told, at its width', () {
    final face = NestAvatar.layerBox(
      const NestAvatarLayer(
        slot: NestAvatarSlot.face,
        image: crown,
        centre: Offset(0.5, 0.3),
        width: 0.4,
      ),
      200,
    );
    expect(face.center, const Offset(100, 60));
    expect(face.width, 80);
  });

  testWidgets('the edit pip is one button named for what it does', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    var taps = 0;
    await pumpKit(
      tester,
      NestEditablePicture(
        label: 'Change Mia’s picture',
        onTap: () => taps++,
        child: const NestAvatar(name: 'Mia', color: MemberColor.coral),
      ),
    );
    expect(find.bySemanticsLabel('Change Mia’s picture'), findsOneWidget);
    await tester.tap(find.byType(NestEditablePicture));
    expect(taps, 1);
    semantics.dispose();
  });

  testWidgets('the hatch reveal ends on the new picture, and under reduce '
      'motion shows only it', (tester) async {
    const before = Text('egg');
    const after = Text('chick');
    await pumpKit(
      tester,
      const NestHatchReveal(
        before: before,
        after: after,
        duration: Duration(seconds: 2),
      ),
    );
    expect(find.text('egg'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('chick'), findsOneWidget);
    expect(find.text('egg'), findsNothing);
    await tester.pumpAndSettle();

    await pumpKit(
      tester,
      const NestHatchReveal(
        key: ValueKey('reduced'),
        before: before,
        after: after,
        duration: Duration(seconds: 2),
      ),
      reduceMotion: true,
    );
    expect(find.text('chick'), findsOneWidget);
    expect(find.text('egg'), findsNothing);
  });

  testWidgets('the circle cropper reports the square it shows', (tester) async {
    Rect? area;
    await pumpKit(
      tester,
      SizedBox(
        width: 300,
        child: NestCircleCropper(
          image: crown,
          imageSize: const Size(400, 200),
          label: 'Fit it in the circle',
          onArea: (value) => area = value,
        ),
      ),
    );
    await tester.pump();
    expect(area, isNotNull);
    expect(area!.left, closeTo(0.25, 0.001));
    expect(area!.top, 0);
    expect(area!.width, closeTo(0.5, 0.001));
    expect(area!.height, closeTo(1, 0.001));
  });
}
