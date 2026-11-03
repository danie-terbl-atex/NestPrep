import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/today/model/home_layout.dart';
import 'package:nestprep/features/today/state/home_layout_controller.dart';

import '../../../support/fake_home_layout_store.dart';

void main() {
  test('starts on the tab bar and takes the layout this phone kept', () async {
    final controller = HomeLayoutController(
      store: FakeHomeLayoutStore(HomeLayout.cards),
      canSwitch: true,
    );
    addTearDown(controller.dispose);

    expect(controller.layout, HomeLayout.tabs);
    await pumpEventQueue();
    expect(controller.layout, HomeLayout.cards);
  });

  test('switching flips the layout and keeps it', () async {
    final store = FakeHomeLayoutStore();
    final controller = HomeLayoutController(store: store, canSwitch: true);
    addTearDown(controller.dispose);

    controller.switchLayout();
    await pumpEventQueue();

    expect(controller.layout, HomeLayout.cards);
    expect(store.kept, HomeLayout.cards);
  });

  test('a switch made before the kept layout is read wins', () async {
    final controller = HomeLayoutController(
      store: FakeHomeLayoutStore(HomeLayout.tabs),
      canSwitch: true,
    )..switchLayout();
    addTearDown(controller.dispose);

    await pumpEventQueue();

    expect(controller.layout, HomeLayout.cards);
  });

  test('a build without the switch stays on the tab bar', () async {
    final store = FakeHomeLayoutStore(HomeLayout.cards);
    final controller = HomeLayoutController(store: store, canSwitch: false)
      ..switchLayout();
    addTearDown(controller.dispose);

    await pumpEventQueue();

    expect(controller.layout, HomeLayout.tabs);
    expect(store.kept, HomeLayout.cards);
  });
}
