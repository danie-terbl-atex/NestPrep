import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/lunch_box/model/lunch_card_content.dart';
import 'package:nestprep/features/lunch_box/model/lunch_card_options.dart';
import 'package:nestprep/features/lunch_box/ui/planner/pdf_lunch_planner_composer.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../support/lunch_card_fixtures.dart';
import '../../../../support/lunch_fixtures.dart';

/// The printable A4 planner (lunch-box ADR-0005): the blank one is the free
/// printable, one page; the filled one is this week, a page per child.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  int pagesIn(pw.Document document) =>
      document.document.pdfPageList.pages.length;

  Future<pw.Document> compose(LunchCardContent? content) async {
    final document = await PdfLunchPlannerComposer().document(
      content: content,
      showsInvite: true,
      inviteHost: 'nestprep.app',
    );
    // Pages are laid out as the document is written.
    await document.save();
    return document;
  }

  test('blank is one A4 page with nobody’s week on it', () async {
    final document = await compose(null);
    expect(pagesIn(document), 1);
    final page = document.document.pdfPageList.pages.single.pageFormat;
    expect(page.width, closeTo(595.28, 0.01));
    expect(page.height, closeTo(841.89, 0.01));
  });

  test('this week for everyone is a page per child', () async {
    final content = LunchCardContent.from(
      LunchCardFixtures.board(),
      const LunchCardOptions(childId: null),
    );
    expect(pagesIn(await compose(content)), 2);
  });

  test('one child’s week is one page', () async {
    final content = LunchCardFixtures.content(
      const LunchCardOptions(childId: LunchFixtures.lwaziId),
    );
    expect(pagesIn(await compose(content)), 1);
  });

  test('what it writes out is a PDF', () async {
    final bytes = await PdfLunchPlannerComposer().compose(
      content: null,
      showsInvite: false,
      inviteHost: null,
    );
    expect(ascii.decode(bytes.sublist(0, 5)), '%PDF-');
    expect(bytes.length, greaterThan(10000));
  });
}
