import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../../shared/failure/app_failure.dart';
import '../../../shared/log/app_log.dart';
import 'lunch_card_sharer.dart';

/// The share sheet through `share_plus`, and printing through `printing`
/// (lunch-box ADR-0005) — the two packages household and documents already
/// use, so a card adds no dependency (`ENG-17`).
final class PlatformLunchCardSharer implements LunchCardSharer {
  PlatformLunchCardSharer({SharePlus? sharePlus})
    : _sharePlus = sharePlus ?? SharePlus.instance;

  final SharePlus _sharePlus;

  @override
  Future<void> shareFile(LunchSharedFile file) async {
    try {
      await _sharePlus.share(
        ShareParams(
          files: [
            XFile.fromData(
              file.bytes,
              mimeType: file.mimeType,
              name: file.fileName,
            ),
          ],
          fileNameOverrides: [file.fileName],
          subject: file.subject,
          text: file.text,
        ),
      );
    } on PlatformException catch (error) {
      AppLog.failure('lunch card share', code: error.code, error: error);
      throw const LunchFailure(LunchProblem.shareUnavailable);
    }
  }

  @override
  Future<void> printPdf({required Uint8List pdf, required String name}) async {
    try {
      final info = await Printing.info();
      if (!info.canPrint) {
        throw const LunchFailure(LunchProblem.printUnavailable);
      }
      await Printing.layoutPdf(onLayout: (_) async => pdf, name: name);
    } on PlatformException catch (error) {
      AppLog.failure('lunch planner print', code: error.code, error: error);
      throw const LunchFailure(LunchProblem.printUnavailable);
    }
  }
}
