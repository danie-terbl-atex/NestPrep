import 'dart:io';

import 'package:flutter/services.dart';

import '../../../shared/failure/app_failure.dart';
import '../../../shared/log/app_log.dart';
import 'recipe_pdf.dart';

abstract interface class SharedPdfInbox {
  /// Null when the phone no longer has it, as after a restart in between.
  Future<PickedPdf?> take(String token);
}

/// The share extension on iOS and `MainActivity` on Android file the PDF;
/// this reads it and deletes the copy at once, so the bytes live only as long
/// as the import screen (recipes ADR-0009).
final class ChannelSharedPdfInbox implements SharedPdfInbox {
  const ChannelSharedPdfInbox({
    this._channel = const MethodChannel('io.nullstate.nestprep/shared_pdf'),
  });

  final MethodChannel _channel;

  @override
  Future<PickedPdf?> take(String token) async {
    final Map<String, String>? filed;
    try {
      filed = await _channel.invokeMapMethod<String, String>('take', {
        'token': token,
      });
    } on PlatformException catch (error) {
      AppLog.failure('shared pdf', code: error.code, error: error);
      return null;
    } on MissingPluginException {
      return null;
    }
    if (filed == null) return null;
    if (filed['tooLarge'] == 'true') {
      throw const OwnRecipeFailure(OwnRecipeProblem.documentTooLarge);
    }
    final path = filed['path'];
    if (path == null) return null;
    final file = File(path);
    try {
      if (await file.length() > FileSelectorRecipePdfPicker.maxBytes) {
        throw const OwnRecipeFailure(OwnRecipeProblem.documentTooLarge);
      }
      return PickedPdf(
        bytes: await file.readAsBytes(),
        name: PickedPdf.nameOf(filed['name'] ?? ''),
      );
    } on FileSystemException catch (error) {
      AppLog.failure('shared pdf', code: 'read', error: error);
      return null;
    } finally {
      if (file.existsSync()) file.deleteSync();
    }
  }
}
