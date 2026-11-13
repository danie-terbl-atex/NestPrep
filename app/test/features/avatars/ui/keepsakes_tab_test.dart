import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/avatars/model/avatar_base.dart';
import 'package:nestprep/features/avatars/model/avatar_buddy.dart';
import 'package:nestprep/features/avatars/model/avatar_catalogue.g.dart';
import 'package:nestprep/features/avatars/model/avatar_choice.dart';
import 'package:nestprep/features/avatars/model/avatar_creation.dart';
import 'package:nestprep/features/avatars/model/avatar_keepsake.dart';
import 'package:nestprep/features/avatars/model/member_avatar_record.dart';
import 'package:nestprep/features/avatars/ui/avatar_studio_tab.dart';
import 'package:nestprep/shared/copy/app_copy.dart';

import '../../../support/avatar_studio_rig.dart';
import '../../../support/household_fixtures.dart';

Finder labelled(String label) => find.byWidgetPredicate(
  (widget) => widget is Semantics && widget.properties.label == label,
);

void main() {
  const worn = '0123456789abcdef0123456789abcdef';
  const other = 'fedcba9876543210fedcba9876543210';
  const portrait = 'aaaaaaaaaaaaaaaabbbbbbbbbbbbbbbb';

  final shelf = [
    AvatarKeepsake(
      id: 'k-drawing',
      memberId: Fixtures.kidMemberId,
      recipe: CreationRecipe.drawing,
      style: CreationStyle.clay,
      imageHash: worn,
      originalPath:
          'households/${Fixtures.householdId}/avatars/${Fixtures.kidMemberId}/keepsakes/k-drawing.jpg',
      createdAt: DateTime(2026, 11, 2),
    ),
    AvatarKeepsake(
      id: 'k-buddy',
      memberId: Fixtures.kidMemberId,
      recipe: CreationRecipe.buddy,
      style: CreationStyle.plush,
      imageHash: other,
      buddy: const AvatarBuddy({
        AvatarBuddyKind.creature: 'owl',
        AvatarBuddyKind.colour: 'blue',
      }),
      createdAt: DateTime(2026, 11, 12),
    ),
  ];

  StudioRig open() => StudioRig(
    member: Fixtures.kid,
    viewerMemberId: Fixtures.kidMemberId,
    record: const MemberAvatarRecord(
      choice: AvatarChoice(base: ImageBase(worn)),
      ownedImages: [worn, other],
    ),
  );

  Future<void> deliver(
    WidgetTester tester,
    StudioRig rig,
    List<AvatarKeepsake> keepsakes,
  ) async {
    rig.avatars.emitKeepsakes(
      Fixtures.kidMemberId,
      [...keepsakes]..sort(AvatarKeepsake.newestFirst),
    );
    await tester.pumpAndSettle();
  }

  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the shelf is newest first, the then beside the now, and says '
      'what is being worn', (tester) async {
    tester.view.physicalSize = const Size(400 * 3, 2400 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final rig = open();
    addTearDown(rig.close);
    rig.photos.atPath[shelf.first.originalPath!] = aPhoto();
    await rig.pump(tester, tab: AvatarStudioTab.keepsakes, asFamily: false);
    await deliver(tester, rig, shelf);

    final buddyTop = tester.getTopLeft(
      find.byKey(const ValueKey('keepsake-k-buddy')),
    );
    final drawingTop = tester.getTopLeft(
      find.byKey(const ValueKey('keepsake-k-drawing')),
    );
    expect(buddyTop.dy, lessThan(drawingTop.dy));
    expect(find.text(AvatarCreationCopy.yourShelf), findsOneWidget);
    expect(find.text(AvatarCreationCopy.then), findsNWidgets(2));
    expect(find.text(AvatarCreationCopy.now), findsNWidgets(2));
    expect(find.text('A blue owl'), findsOneWidget);
    expect(find.text(AvatarCreationCopy.wearing), findsOneWidget);
    expect(find.text(AvatarCreationCopy.useAgain), findsOneWidget);
    expect(
      labelled(AvatarCreationCopy.originalLabel(CreationRecipe.drawing)),
      findsOneWidget,
    );
  });

  testWidgets('use again puts the picture back on', (tester) async {
    final rig = open();
    addTearDown(rig.close);
    await rig.pump(tester, tab: AvatarStudioTab.keepsakes, asFamily: false);
    await deliver(tester, rig, shelf);
    await scrollTo(tester, find.text(AvatarCreationCopy.useAgain));
    await tester.tap(find.text(AvatarCreationCopy.useAgain));
    await tester.pumpAndSettle();
    expect(rig.avatars.chosen.last.choice.base, const ImageBase(other));
    expect(rig.avatars.chosen.last.by, Fixtures.kidMemberId);
  });

  testWidgets('delete asks first, then sends the request by the keepsake '
      'id', (tester) async {
    final rig = open();
    addTearDown(rig.close);
    await rig.pump(tester, tab: AvatarStudioTab.keepsakes, asFamily: false);
    await deliver(tester, rig, shelf);
    final delete = find.text(AvatarCreationCopy.delete).first;
    await scrollTo(tester, delete);
    await tester.tap(delete);
    await tester.pumpAndSettle();
    expect(find.text(AvatarCreationCopy.deleteConfirm), findsOneWidget);
    await tester.tap(find.text(AvatarCreationCopy.keepIt));
    await tester.pumpAndSettle();
    expect(rig.avatars.keepsakeDeletes, isEmpty);

    await tester.tap(find.text(AvatarCreationCopy.delete).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(AvatarCreationCopy.delete).last);
    await tester.pumpAndSettle();
    expect(rig.avatars.keepsakeDeletes.single, (
      keepsakeId: 'k-buddy',
      by: Fixtures.kidMemberId,
    ));
    expect(find.text(AvatarCreationCopy.deleting), findsOneWidget);

    await deliver(tester, rig, [shelf.first]);
    expect(find.byKey(const ValueKey('keepsake-k-buddy')), findsNothing);
  });

  testWidgets('a portrait sits on the shelf whole, and is never worn', (
    tester,
  ) async {
    final rig = StudioRig(member: Fixtures.sam);
    addTearDown(rig.close);
    await rig.pump(tester, tab: AvatarStudioTab.keepsakes);
    rig.avatars.emitKeepsakes(Fixtures.samMemberId, [
      const AvatarKeepsake(
        id: 'k-portrait',
        memberId: Fixtures.samMemberId,
        recipe: CreationRecipe.portrait,
        imageHash: portrait,
      ),
    ]);
    await tester.pumpAndSettle();
    expect(labelled(AvatarCreationCopy.portraitLabel), findsOne);
    expect(find.text(AvatarCreationCopy.useAgain), findsNothing);
    expect(find.text(AvatarCreationCopy.then), findsNothing);
  });

  testWidgets('an empty shelf says what lands there, and opens Create', (
    tester,
  ) async {
    final rig = open();
    addTearDown(rig.close);
    await rig.pump(tester, tab: AvatarStudioTab.keepsakes, asFamily: false);
    expect(find.text(AvatarCreationCopy.emptyTitle), findsOneWidget);
    await scrollTo(tester, find.text(AvatarCreationCopy.emptyAction));
    await tester.tap(find.text(AvatarCreationCopy.emptyAction));
    await tester.pumpAndSettle();
    expect(find.text(AvatarCreationCopy.menuTitle), findsOneWidget);
  });

  testWidgets('a parent reads the child’s shelf by name', (tester) async {
    final rig = StudioRig(member: Fixtures.kid);
    addTearDown(rig.close);
    await rig.pump(tester, tab: AvatarStudioTab.keepsakes);
    expect(
      find.text(AvatarCreationCopy.shelfOf(Fixtures.kid.displayName)),
      findsOneWidget,
    );
  });

  for (final brightness in Brightness.values) {
    testWidgets('the shelf holds in ${brightness.name} at 200% text on a '
        '360-wide phone', (tester) async {
      tester.view.physicalSize = const Size(360 * 3, 800 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final rig = open();
      addTearDown(rig.close);
      await rig.pump(
        tester,
        tab: AvatarStudioTab.keepsakes,
        asFamily: false,
        brightness: brightness,
        textScale: 2,
      );
      await deliver(tester, rig, shelf);
      for (var i = 0; i < 8; i++) {
        await tester.drag(find.byType(ListView).first, const Offset(0, -500));
        await tester.pump();
      }
      expect(tester.takeException(), isNull);
    });
  }
}
