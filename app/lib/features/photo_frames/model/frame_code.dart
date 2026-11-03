import '../../kid_accounts/state/kid_code_controller.dart';

abstract final class FrameCode {
  static const length = KidCodeController.codeLength;
  static const scheme = 'nestprep';
  static const host = 'frame';

  static String normalise(String typed) => KidCodeController.normalise(typed);

  static bool isComplete(String code) =>
      code.length == length && normalise(code) == code;

  static String? fromScan(String raw) {
    final text = raw.trim();
    final uri = Uri.tryParse(text);
    final candidate =
        uri != null &&
            uri.scheme.toLowerCase() == scheme &&
            uri.host.toLowerCase() == host &&
            uri.pathSegments.length == 1
        ? uri.pathSegments.single
        : text;
    final code = candidate.toUpperCase();
    return isComplete(code) ? code : null;
  }
}
