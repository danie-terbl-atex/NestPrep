import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../shared/failure/app_failure.dart';
import '../../../shared/log/app_log.dart';
import 'card_image_sharer.dart';

/// The share sheet, through `share_plus`, with the card as a PNG made in
/// memory. Nothing is written to the phone's gallery or to the household.
final class PlatformCardImageSharer implements CardImageSharer {
  PlatformCardImageSharer({SharePlus? sharePlus})
    : _sharePlus = sharePlus ?? SharePlus.instance;

  final SharePlus _sharePlus;

  @override
  Future<void> share({
    required Uint8List png,
    required String fileName,
    required String text,
  }) async {
    try {
      await _sharePlus.share(
        ShareParams(
          text: text,
          files: [XFile.fromData(png, mimeType: 'image/png', name: fileName)],
          fileNameOverrides: [fileName],
        ),
      );
    } on PlatformException catch (error) {
      AppLog.failure('mental load share', code: error.code, error: error);
      throw const MentalLoadFailure(MentalLoadProblem.shareUnavailable);
    }
  }
}
