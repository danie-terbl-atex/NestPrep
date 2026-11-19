import '../../../shared/links/app_link_site.dart';
import '../../kid_accounts/state/kid_code_controller.dart';

/// The code a frame shows while it waits to be linked. Its QR is
/// `nestprep://frame/<CODE>`; `https://app.nestprep.io/frame/<CODE>` is read
/// the same way, for when the frame moves to it (household ADR-0012).
abstract final class FrameCode {
  static const length = KidCodeController.codeLength;
  static const segment = 'frame';

  static String normalise(String typed) => KidCodeController.normalise(typed);

  static bool isComplete(String code) =>
      code.length == length && normalise(code) == code;

  static String? fromLink(Uri uri) {
    final candidate = AppLinkSite.segmentAfter(segment, uri);
    return candidate == null ? null : _code(candidate);
  }

  static String? fromScan(String raw) {
    final text = raw.trim();
    final uri = Uri.tryParse(text);
    return uri != null && uri.hasScheme ? fromLink(uri) : _code(text);
  }

  static String? _code(String candidate) {
    final code = candidate.toUpperCase();
    return isComplete(code) ? code : null;
  }
}
