import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/appearance/model/appearance.dart';
import 'package:nestprep/features/appearance/state/appearance_controller.dart';

import '../../../support/fake_appearance_store.dart';

void main() {
  test('starts on auto and takes the choice this phone kept', () async {
    final controller = AppearanceController(
      store: FakeAppearanceStore(Appearance.night),
    );
    addTearDown(controller.dispose);

    expect(controller.appearance, Appearance.auto);
    await pumpEventQueue();
    expect(controller.appearance, Appearance.night);
  });

  test('choosing changes it at once and keeps it', () async {
    final store = FakeAppearanceStore();
    final controller = AppearanceController(store: store);
    addTearDown(controller.dispose);
    var told = 0;
    controller.addListener(() => told++);

    controller.choose(Appearance.day);
    await pumpEventQueue();

    expect(controller.appearance, Appearance.day);
    expect(store.kept, Appearance.day);
    expect(told, 1);
  });

  test('a choice made before the kept one is read wins', () async {
    final store = FakeAppearanceStore(Appearance.night);
    final controller = AppearanceController(store: store)
      ..choose(Appearance.day);
    addTearDown(controller.dispose);

    await pumpEventQueue();

    expect(controller.appearance, Appearance.day);
    expect(store.kept, Appearance.day);
  });

  test('choosing what is already on writes nothing', () async {
    final store = FakeAppearanceStore();
    final controller = AppearanceController(store: store)
      ..choose(Appearance.auto);
    addTearDown(controller.dispose);

    await pumpEventQueue();

    expect(store.writes, 0);
  });

  test('each choice is the theme mode the app is built with', () {
    expect(Appearance.auto.themeMode, ThemeMode.system);
    expect(Appearance.day.themeMode, ThemeMode.light);
    expect(Appearance.night.themeMode, ThemeMode.dark);
    for (final appearance in Appearance.values) {
      expect(Appearance.fromName(appearance.name), appearance);
    }
    expect(Appearance.fromName('sepia'), isNull);
  });
}
