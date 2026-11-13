import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/avatars/data/avatar_repository.dart';
import 'package:nestprep/features/avatars/ui/avatar_shop_switch.dart';
import 'package:nestprep/features/household/model/household_view.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:provider/provider.dart';

import '../../../support/fake_avatars.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/pump_screen.dart';

void main() {
  Future<FakeAvatarRepository> pump(
    WidgetTester tester, {
    String viewerUid = Fixtures.samUid,
    bool isOpen = true,
  }) async {
    final avatars = FakeAvatarRepository();
    await pumpScreen(
      tester,
      const Scaffold(body: SingleChildScrollView(child: AvatarShopSwitch())),
      providers: [Provider<AvatarRepository>.value(value: avatars)],
      view: HouseholdView(
        household: Fixtures.household().copyWith(avatarShop: isOpen),
        members: [Fixtures.sam, Fixtures.thandi, Fixtures.kid],
        viewerUid: viewerUid,
      ),
      textScale: 2,
      brightness: Brightness.dark,
    );
    return avatars;
  }

  testWidgets('a parent turns the star shop off, and the words say what it '
      'does', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final avatars = await pump(tester);
    expect(find.text(AvatarCopy.shopSwitchTitle), findsOneWidget);
    expect(find.text(AvatarCopy.shopSwitchBody), findsOneWidget);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(avatars.shopSwitched, [false]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('it shows the switch the household holds', (tester) async {
    await pump(tester, isOpen: false);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
  });

  testWidgets('a helper never sees it', (tester) async {
    await pump(tester, viewerUid: Fixtures.thandiUid);
    expect(find.text(AvatarCopy.shopSwitchTitle), findsNothing);
  });
}
