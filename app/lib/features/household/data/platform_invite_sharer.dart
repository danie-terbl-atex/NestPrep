import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../shared/log/app_log.dart';
import 'invite_sharer.dart';

/// The share sheet, through `share_plus` (household ADR-0003).
///
/// The link comes from `--dart-define=NESTPREP_INVITE_LINK=https://…`, the
/// page that says how to get the app. Without it the invite is the code and
/// the app's name, which is enough to join (household ADR-0002).
final class PlatformInviteSharer implements InviteSharer {
  PlatformInviteSharer({SharePlus? sharePlus, String? configuredLink})
    : _sharePlus = sharePlus ?? SharePlus.instance,
      appLink = _parse(configuredLink ?? _fromEnvironment);

  static const _fromEnvironment = String.fromEnvironment(
    'NESTPREP_INVITE_LINK',
  );

  final SharePlus _sharePlus;

  @override
  final Uri? appLink;

  static Uri? _parse(String value) {
    final uri = Uri.tryParse(value.trim());
    return uri != null && uri.hasScheme && uri.host.isNotEmpty ? uri : null;
  }

  @override
  Future<InviteShareOutcome> share({
    required String subject,
    required String text,
  }) async {
    try {
      final result = await _sharePlus.share(
        ShareParams(subject: subject, text: text),
      );
      return switch (result.status) {
        ShareResultStatus.success => InviteShareOutcome.shared,
        ShareResultStatus.dismissed => InviteShareOutcome.dismissed,
        // Android cannot say what was picked, only that the sheet opened.
        ShareResultStatus.unavailable => InviteShareOutcome.shared,
      };
    } on PlatformException catch (error) {
      // The sheet would not open. The code is on screen with a copy button, so
      // the person can still send it — this is translated, not lost.
      AppLog.failure('invite share', code: error.code, error: error);
      return InviteShareOutcome.unavailable;
    }
  }
}
