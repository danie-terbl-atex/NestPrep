import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/accounts/ui/sign_in_welcome.dart';
import 'package:nestprep/shared/copy/app_copy.dart';

import '../../../support/pump_kit.dart';

double _photoScale(WidgetTester tester) => tester
    .widget<Transform>(
      find.descendant(
        of: find.byType(NestPhotoFrame),
        matching: find.byType(Transform),
      ),
    )
    .transform
    .getMaxScaleOnAxis();

void main() {
  testWidgets('the photo drifts in once and comes to rest', (tester) async {
    await pumpKit(tester, const SingleChildScrollView(child: SignInWelcome()));
    expect(_photoScale(tester), 1);

    await tester.pumpAndSettle();

    expect(_photoScale(tester), closeTo(NestMotion.driftScale, 0.001));
    expect(find.text(AppCopy.brandLine), findsOneWidget);
  });

  testWidgets('under reduced motion the photo never moves', (tester) async {
    await pumpKit(
      tester,
      const SingleChildScrollView(child: SignInWelcome()),
      reduceMotion: true,
    );
    await tester.pumpAndSettle();

    expect(_photoScale(tester), 1);
  });
}
