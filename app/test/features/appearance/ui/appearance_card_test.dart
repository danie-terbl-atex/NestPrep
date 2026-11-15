import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/appearance/state/appearance_controller.dart';
import 'package:nestprep/features/appearance/ui/appearance_card.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:provider/provider.dart';

import '../../../support/fake_appearance_store.dart';

/// The choice turns the whole app, whatever the phone is set to, and the
/// status bar turns with it (design-system ADR-0024). Built the way
/// `NestPrepApp` builds its `MaterialApp`.
void main() {
  Future<AppearanceController> pumpApp(
    WidgetTester tester, {
    Brightness phone = Brightness.light,
  }) async {
    tester.platformDispatcher.platformBrightnessTestValue = phone;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    final controller = AppearanceController(store: FakeAppearanceStore());
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider<AppearanceController>.value(
        value: controller,
        child: Builder(
          builder: (context) => MaterialApp(
            theme: nestThemeData(NestTheme.light()),
            darkTheme: nestThemeData(NestTheme.dark()),
            themeMode:
                context.watch<AppearanceController?>()?.appearance.themeMode ??
                ThemeMode.system,
            home: const NestScaffold(body: AppearanceCard()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return controller;
  }

  bool isDark(WidgetTester tester) =>
      NestTheme.of(tester.element(find.byType(AppearanceCard))).isDark;

  SystemUiOverlayStyle statusBar(WidgetTester tester) => tester
      .widget<AnnotatedRegion<SystemUiOverlayStyle>>(
        find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
      )
      .value;

  testWidgets('auto follows the phone', (tester) async {
    await pumpApp(tester, phone: Brightness.dark);

    expect(isDark(tester), isTrue);
  });

  testWidgets('night on a phone set to light turns the app and its status '
      'bar dark', (tester) async {
    await pumpApp(tester);
    expect(isDark(tester), isFalse);
    expect(statusBar(tester), SystemUiOverlayStyle.dark);

    await tester.tap(find.text(AppearanceCopy.night));
    await tester.pumpAndSettle();

    expect(isDark(tester), isTrue);
    expect(statusBar(tester), SystemUiOverlayStyle.light);
  });

  testWidgets('day on a phone set to dark turns the app light', (tester) async {
    await pumpApp(tester, phone: Brightness.dark);

    await tester.tap(find.text(AppearanceCopy.day));
    await tester.pumpAndSettle();

    expect(isDark(tester), isFalse);
  });
}
