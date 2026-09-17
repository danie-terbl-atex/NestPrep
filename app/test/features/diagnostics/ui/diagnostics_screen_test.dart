import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/diagnostics/model/emulator_ping.dart';
import 'package:nestprep/features/diagnostics/state/ping_list_controller.dart';
import 'package:nestprep/features/diagnostics/ui/diagnostics_screen.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:provider/provider.dart';

import '../../../support/fake_ping_repository.dart';

void main() {
  late FakePingRepository repository;

  setUp(() => repository = FakePingRepository());
  tearDown(() => repository.close());

  Future<void> pumpScreen(WidgetTester tester) => tester.pumpWidget(
    MediaQuery(
      data: const MediaQueryData(disableAnimations: true),
      child: ChangeNotifierProvider(
        create: (_) => PingListController(repository, sentFrom: 'test'),
        child: MaterialApp(
          theme: nestThemeData(NestTheme.light()),
          home: const DiagnosticsScreen(),
        ),
      ),
    ),
  );

  testWidgets('holds the layout with skeletons until the stream emits', (
    tester,
  ) async {
    await pumpScreen(tester);
    expect(find.byType(NestSkeleton), findsWidgets);
  });

  testWidgets('shows the empty state with a way to send a ping', (
    tester,
  ) async {
    await pumpScreen(tester);
    repository.emit(const []);
    await tester.pump();
    expect(find.text(AppCopy.diagnosticsEmptyTitle), findsOneWidget);

    await tester.tap(find.text(AppCopy.diagnosticsSendPing).first);
    await tester.pump();
    expect(repository.sent, ['test']);
  });

  testWidgets('shows user-facing copy and a retry on failure', (tester) async {
    await pumpScreen(tester);
    repository.emitError(const UnavailableFailure());
    await tester.pump();
    expect(
      find.text(AppCopy.failure(const UnavailableFailure())),
      findsOneWidget,
    );
    expect(find.text(AppCopy.retry), findsOneWidget);
  });

  testWidgets('lists pings once data arrives', (tester) async {
    await pumpScreen(tester);
    repository.emit([
      EmulatorPing(id: '1', sentFrom: 'android', sentAt: DateTime.utc(2026)),
      const EmulatorPing(id: '2', sentFrom: 'ios'),
    ]);
    await tester.pump();
    expect(find.byType(NestListRow), findsNWidgets(2));
    expect(find.text(AppCopy.diagnosticsPingPending), findsOneWidget);
  });

  testWidgets('a failed send shows a banner with a retry', (tester) async {
    repository.failSendWith = const UnavailableFailure();
    await pumpScreen(tester);
    repository.emit(const []);
    await tester.pump();
    await tester.tap(find.text(AppCopy.diagnosticsSendPing).first);
    await tester.pump();
    expect(find.byType(NestBanner), findsOneWidget);
  });
}
