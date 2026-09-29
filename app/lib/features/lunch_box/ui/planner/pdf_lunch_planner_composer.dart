import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../design/nest_kit.dart';
import '../../../../shared/copy/app_copy.dart';
import '../../data/lunch_planner_composer.dart';
import '../../model/lunch_card_content.dart';
import 'lunch_planner_kit.dart';
import 'lunch_planner_page.dart';

/// The planner as an A4 PDF, composed on the phone with `pdf` (lunch-box
/// ADR-0005): one page when blank, one page per child when filled.
final class PdfLunchPlannerComposer implements LunchPlannerComposer {
  PdfLunchPlannerComposer({AssetBundle? bundle})
    : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;

  /// The fonts and images, read once for the life of the screen.
  Future<LunchPlannerKit>? _kit;

  @override
  Future<Uint8List> compose({
    required LunchCardContent? content,
    required bool showsInvite,
    required String? inviteHost,
  }) async => (await document(
    content: content,
    showsInvite: showsInvite,
    inviteHost: inviteHost,
  )).save();

  /// The document before it is written out — what a test counts pages in.
  Future<pw.Document> document({
    required LunchCardContent? content,
    required bool showsInvite,
    required String? inviteHost,
  }) async {
    final kit = await (_kit ??= LunchPlannerKit.load(_bundle));
    final document = pw.Document(title: LunchShareCopy.plannerTitle);
    final children = content?.children ?? const <LunchCardChild?>[null];
    for (final child in children) {
      final page = LunchPlannerPage(
        kit: kit,
        week: content?.week,
        child: child,
        showsInvite: showsInvite,
        inviteHost: inviteHost,
      );
      document.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(NestSpace.xxxl),
          build: (context) => page.build(),
        ),
      );
    }
    return document;
  }
}
