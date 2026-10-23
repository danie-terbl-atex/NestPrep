import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/lunch_box/model/lunch_card_format.dart';
import 'package:nestprep/features/lunch_box/model/lunch_card_naming.dart';
import 'package:nestprep/features/lunch_box/model/lunch_card_options.dart';
import 'package:nestprep/features/lunch_box/ui/card/lunch_share_card.dart';

import '../../../support/lunch_card_fixtures.dart';
import '../../../support/lunch_fixtures.dart';
import '../../../support/real_fonts.dart';

/// A shared card says what is in the boxes whole (lunch-box ADR-0005): the
/// type shrinks to the room rather than any name ending in an ellipsis, in
/// every format, for one child's week and for the family's. Measured in the
/// brand's real fonts, because the fit is the font's.
void main() {
  setUpAll(loadEveryFont);

  for (final format in LunchCardFormat.values) {
    for (final childId in [LunchFixtures.lwaziId, null]) {
      final who = childId == null ? 'every child' : 'one child';
      testWidgets('a ${format.name} for $who cuts no words off', (
        tester,
      ) async {
        final options = LunchCardOptions(
          childId: childId,
          format: format,
          naming: LunchCardNaming.firstNames,
        );
        tester.view
          ..physicalSize = format.exportSize
          ..devicePixelRatio = LunchCardFormat.pixelRatio;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          Center(
            child: LunchShareCard(
              content: LunchCardFixtures.content(options),
              format: format,
              style: options.style,
              showsInvite: true,
              inviteHost: 'nestprep.app',
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        final cut = [
          for (final paragraph
              in tester.allRenderObjects.whereType<RenderParagraph>())
            if (paragraph.didExceedMaxLines) paragraph.text.toPlainText(),
        ];
        expect(cut, isEmpty);
        // Every main of the week is on the card.
        final said = tester.allRenderObjects
            .whereType<RenderParagraph>()
            .map((paragraph) => paragraph.text.toPlainText())
            .join(' ');
        final content = LunchCardFixtures.content(options);
        for (final main in content.mainNames) {
          expect(said, contains(main));
        }
      });
    }
  }
}
