import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/account_data/state/account_deletion_controller.dart';
import 'package:nestprep/features/account_data/state/account_export_controller.dart';
import 'package:nestprep/features/account_data/ui/account_centre_screen.dart';
import 'package:nestprep/features/account_data/ui/account_export_screen.dart';
import 'package:nestprep/features/account_data/ui/delete_account_screen.dart';
import 'package:nestprep/features/feedback/model/feedback_draft.dart';
import 'package:nestprep/features/feedback/state/feedback_controller.dart';
import 'package:nestprep/features/feedback/ui/feedback_screen.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../test/support/fake_account_data.dart';
import '../test/support/fake_feedback.dart';
import 'review_press.dart';

/// Account and privacy, Download my data (ready to share) and Delete my
/// account (a hand-over, an ending and a store subscription), and Send
/// feedback half written and sent, in both themes (accounts ADR-0006,
/// feedback ADR-0001). Pictures to look at rather than assertions:
///
///     flutter test tool/account_data_design_review_test.dart --update-goldens
void main() {
  setUpAll(() async {
    tz_data.initializeTimeZones();
    await loadEveryFont();
  });

  for (final brightness in Brightness.values) {
    final theme = brightness.name;

    testWidgets('account-centre-$theme', (tester) async {
      await captureScreen(
        tester,
        'account-centre-$theme',
        brightness: brightness,
        screen: const AccountCentreScreen(),
        providers: const [],
        emit: () async {},
      );
    });

    testWidgets('download-my-data-$theme', (tester) async {
      final controller = AccountExportController(
        accountDataGateway: FakeAccountDataGateway(),
        exportSharer: FakeExportSharer(),
      );
      addTearDown(controller.dispose);
      await captureScreen(
        tester,
        'download-my-data-$theme',
        brightness: brightness,
        screen: ChangeNotifierProvider.value(
          value: controller,
          child: const AccountExportScreen(),
        ),
        providers: const [],
        emit: controller.prepare,
        act: () =>
            tester.drag(find.byType(Scrollable).first, const Offset(0, -600)),
      );
    });

    testWidgets('delete-my-account-$theme', (tester) async {
      final controller = AccountDeletionController(
        accountDataGateway: FakeAccountDataGateway(),
        signOut: () async {},
      );
      addTearDown(controller.dispose);
      await captureScreen(
        tester,
        'delete-my-account-$theme',
        brightness: brightness,
        screen: ChangeNotifierProvider.value(
          value: controller,
          child: const DeleteAccountScreen(),
        ),
        providers: const [],
        emit: () async {},
      );
    });

    FeedbackController feedback() {
      final controller = FeedbackController(
        repository: FakeFeedbackRepository(),
        uid: 'uid-sam',
      );
      addTearDown(controller.dispose);
      return controller;
    }

    testWidgets('send-feedback-$theme', (tester) async {
      final controller = feedback();
      await captureScreen(
        tester,
        'send-feedback-$theme',
        brightness: brightness,
        screen: ChangeNotifierProvider.value(
          value: controller,
          child: const FeedbackScreen(),
        ),
        providers: const [],
        emit: () async {
          controller
            ..chooseKind(FeedbackKind.problem)
            ..chooseArea(FeedbackArea.groceries);
        },
      );
    });

    testWidgets('send-feedback-sent-$theme', (tester) async {
      final controller = feedback();
      await captureScreen(
        tester,
        'send-feedback-sent-$theme',
        brightness: brightness,
        screen: ChangeNotifierProvider.value(
          value: controller,
          child: const FeedbackScreen(),
        ),
        providers: const [],
        emit: () async {
          controller
            ..chooseKind(FeedbackKind.praise)
            ..setMessage('Love the lunch board');
          await controller.send();
        },
      );
    });
  }
}
