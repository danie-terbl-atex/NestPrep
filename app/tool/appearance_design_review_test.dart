import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/appearance/model/appearance.dart';
import 'package:nestprep/features/appearance/state/appearance_controller.dart';
import 'package:nestprep/features/household/ui/household_more_screen.dart';
import 'package:provider/provider.dart';

import '../test/support/fake_appearance_store.dart';
import 'review_press.dart';

/// The foot of More, where day or night is chosen for this phone
/// (design-system ADR-0024), in both themes and at 200% text. Pictures to
/// look at rather than assertions: regenerate with
///
///     flutter test tool/appearance_design_review_test.dart --update-goldens
void main() {
  setUpAll(loadEveryFont);

  for (final (name, brightness, scale, chosen) in [
    ('more-appearance-light', Brightness.light, 1.0, Appearance.auto),
    ('more-appearance-dark', Brightness.dark, 1.0, Appearance.night),
    (
      'more-appearance-dark-200-percent-text',
      Brightness.dark,
      2.0,
      Appearance.night,
    ),
  ]) {
    testWidgets(name, (tester) async {
      final controller = AppearanceController(
        store: FakeAppearanceStore(chosen),
      );
      addTearDown(controller.dispose);
      await captureScreen(
        tester,
        name,
        brightness: brightness,
        textScale: scale,
        screen: HouseholdMoreScreen(onSelectTab: (_) {}),
        providers: [
          ChangeNotifierProvider<AppearanceController>.value(value: controller),
        ],
        emit: () async {},
        act: () =>
            tester.drag(find.byType(Scrollable).first, const Offset(0, -4000)),
      );
    });
  }
}
