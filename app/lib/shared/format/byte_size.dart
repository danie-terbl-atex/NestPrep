import '../copy/app_copy.dart';

/// Every file size a person reads is formatted here (`FE-19`).
///
/// Binary units, because that is what the 20 MiB cap in `storage.rules` counts
/// in — a file the rules refuse must not read as "20 MB" on the screen that
/// refused it.
abstract final class NestBytes {
  static const _step = 1024;

  static String format(int bytes) {
    if (bytes <= 0) return '0 ${AppCopy.byteUnits.first}';

    var size = bytes.toDouble();
    var unit = 0;
    while (size >= _step && unit < AppCopy.byteUnits.length - 1) {
      size /= _step;
      unit++;
    }

    // Whole numbers below a kilobyte; one decimal above, and none at all once
    // it is big enough that the decimal is noise.
    final digits = unit == 0 || size >= 100 ? 0 : 1;
    return '${size.toStringAsFixed(digits)} ${AppCopy.byteUnits[unit]}';
  }
}
