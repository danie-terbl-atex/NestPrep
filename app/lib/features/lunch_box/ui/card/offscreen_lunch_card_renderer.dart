import 'dart:typed_data';

import '../../../../shared/failure/app_failure.dart';
import '../../../../shared/log/app_log.dart';
import '../../data/lunch_card_renderer.dart';
import '../../data/offscreen_widget_renderer.dart';
import '../../model/lunch_card_content.dart';
import '../../model/lunch_card_format.dart';
import '../../model/lunch_card_options.dart';
import 'lunch_share_card.dart';

/// The card drawn offscreen, at its format's export size (lunch-box
/// ADR-0005).
final class OffscreenLunchCardRenderer implements LunchCardRenderer {
  const OffscreenLunchCardRenderer({
    this.renderer = const OffscreenWidgetRenderer(),
  });

  final OffscreenWidgetRenderer renderer;

  @override
  Future<Uint8List> render({
    required LunchCardContent content,
    required LunchCardOptions options,
    required String? inviteHost,
  }) async {
    try {
      return await renderer.renderPng(
        LunchShareCard(
          content: content,
          format: options.format,
          style: options.style,
          showsInvite: options.showsInvite,
          inviteHost: inviteHost,
        ),
        logicalSize: options.format.logicalSize,
        pixelRatio: LunchCardFormat.pixelRatio,
      );
    } on Exception catch (error) {
      // An asset that would not decode or an engine that would not encode:
      // the parent can try again, and the reason goes to the log.
      AppLog.failure('lunch card render', code: 'render', error: error);
      throw const LunchFailure(LunchProblem.cardNotDrawn);
    } on StateError catch (error) {
      AppLog.failure('lunch card render', code: 'no-bytes', error: error);
      throw const LunchFailure(LunchProblem.cardNotDrawn);
    }
  }
}
