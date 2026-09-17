import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/shared/async/async_state.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../support/pump_kit.dart';

void main() {
  Widget view(AsyncState<List<String>> state, {VoidCallback? onRetry}) =>
      NestAsyncView<List<String>>(
        state: state,
        isEmpty: (items) => items.isEmpty,
        onRetry: onRetry ?? () {},
        emptyBuilder: (_) => const Text('nothing here'),
        dataBuilder: (_, items) => Text(items.join(',')),
      );

  for (final brightness in bothThemes) {
    group(brightness.name, () {
      testWidgets('loading holds the layout with skeleton rows', (
        tester,
      ) async {
        await pumpKit(
          tester,
          view(const AsyncLoading()),
          brightness: brightness,
          reduceMotion: true,
        );
        expect(find.byType(NestSkeleton), findsWidgets);
      });

      testWidgets('failure shows human copy and retries', (tester) async {
        var retries = 0;
        await pumpKit(
          tester,
          view(
            const AsyncFailure(PermissionDeniedFailure()),
            onRetry: () => retries++,
          ),
          brightness: brightness,
          reduceMotion: true,
        );
        expect(
          find.text(AppCopy.failure(const PermissionDeniedFailure())),
          findsOneWidget,
        );
        await tester.tap(find.text(AppCopy.retry));
        expect(retries, 1);
      });

      testWidgets('empty data renders the empty builder', (tester) async {
        await pumpKit(
          tester,
          view(const AsyncData([])),
          brightness: brightness,
          reduceMotion: true,
        );
        expect(find.text('nothing here'), findsOneWidget);
      });

      testWidgets('data renders the data builder', (tester) async {
        await pumpKit(
          tester,
          view(const AsyncData(['a', 'b'])),
          brightness: brightness,
          reduceMotion: true,
        );
        expect(find.text('a,b'), findsOneWidget);
      });
    });
  }
}
