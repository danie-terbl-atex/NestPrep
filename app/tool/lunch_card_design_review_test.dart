import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/lunch_box/model/lunch_card_content.dart';
import 'package:nestprep/features/lunch_box/model/lunch_card_format.dart';
import 'package:nestprep/features/lunch_box/model/lunch_card_naming.dart';
import 'package:nestprep/features/lunch_box/model/lunch_card_options.dart';
import 'package:nestprep/features/lunch_box/model/lunch_card_style.dart';
import 'package:nestprep/features/lunch_box/ui/card/offscreen_lunch_card_renderer.dart';
import 'package:nestprep/features/lunch_box/ui/planner/pdf_lunch_planner_composer.dart';

import '../test/support/lunch_card_fixtures.dart';
import '../test/support/lunch_fixtures.dart';
import 'review_press.dart';

/// The shareable lunch cards exactly as they are exported — the offscreen
/// render's own PNG, at 1080 wide, in the brand's real fonts — for a design
/// verdict (lunch-box ADR-0005) — and the printable planner, blank and
/// filled, as the PDFs a parent prints. Regenerate with
///
///     flutter test tool/lunch_card_design_review_test.dart --update-goldens
///
/// then turn each PDF into a picture to look at:
///
///     sips -s format png design-review/lunch-planner-blank.pdf \
///       --out design-review/lunch-planner-blank.png
void main() {
  setUpAll(loadEveryFont);

  Future<void> press(
    WidgetTester tester,
    String name,
    LunchCardOptions options, {
    String? inviteHost = 'nestprep.app',
  }) async {
    final image = await tester.runAsync(() async {
      final Uint8List png = await const OffscreenLunchCardRenderer().render(
        content: LunchCardFixtures.content(options),
        options: options,
        inviteHost: inviteHost,
      );
      final codec = await ui.instantiateImageCodec(png);
      return (await codec.getNextFrame()).image;
    });
    await expectLater(image!, matchesGoldenFile('../design-review/$name.png'));
  }

  const lwazi = LunchFixtures.lwaziId;

  testWidgets(
    'a story, cream, initials',
    (tester) => press(
      tester,
      'lunch-card-story-cream',
      const LunchCardOptions(childId: lwazi),
    ),
  );

  testWidgets(
    'a story, forest, no names',
    (tester) => press(
      tester,
      'lunch-card-story-forest',
      const LunchCardOptions(
        childId: lwazi,
        style: LunchCardStyle.forest,
        naming: LunchCardNaming.none,
      ),
    ),
  );

  testWidgets(
    'a square post, leaf, a first name',
    (tester) => press(
      tester,
      'lunch-card-post-leaf',
      const LunchCardOptions(
        childId: lwazi,
        format: LunchCardFormat.post,
        style: LunchCardStyle.leaf,
        naming: LunchCardNaming.firstNames,
      ),
    ),
  );

  testWidgets(
    'WhatsApp, straw, no invite line',
    (tester) => press(
      tester,
      'lunch-card-chat-straw',
      const LunchCardOptions(
        childId: lwazi,
        format: LunchCardFormat.chat,
        style: LunchCardStyle.straw,
        showsInvite: false,
      ),
    ),
  );

  testWidgets(
    'everyone on a story, cream, first names',
    (tester) => press(
      tester,
      'lunch-card-family-story-cream',
      const LunchCardOptions(childId: null, naming: LunchCardNaming.firstNames),
    ),
  );

  testWidgets(
    'everyone on a square post, forest, initials',
    (tester) => press(
      tester,
      'lunch-card-family-post-forest',
      const LunchCardOptions(
        childId: null,
        format: LunchCardFormat.post,
        style: LunchCardStyle.forest,
      ),
    ),
  );

  test('the planner, blank and filled, as PDFs', () async {
    final composer = PdfLunchPlannerComposer();
    Future<void> write(String name, LunchCardContent? content) async =>
        File('design-review/$name.pdf').writeAsBytes(
          await composer.compose(
            content: content,
            showsInvite: true,
            inviteHost: 'nestprep.app',
          ),
        );
    await write('lunch-planner-blank', null);
    await write(
      'lunch-planner-filled',
      LunchCardFixtures.content(
        const LunchCardOptions(childId: LunchFixtures.lwaziId),
      ),
    );
  });
}
