import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/format/byte_size.dart';

/// A file size on a row is one of the two things that answer "is this the one
/// I want" without downloading anything. The other is who put it there.
///
/// Binary units, deliberately: the cap in `storage.rules` counts in MiB, and a
/// file the rules refuse must not read as "20 MB" on the screen that refused it.
void main() {
  test('nothing is not a file', () {
    expect(NestBytes.format(0), '0 ${AppCopy.byteUnits.first}');
    expect(NestBytes.format(-1), '0 ${AppCopy.byteUnits.first}');
  });

  test('bytes are whole numbers, because a decimal byte is noise', () {
    expect(NestBytes.format(1), '1 B');
    expect(NestBytes.format(999), '999 B');
  });

  test('a kilobyte is 1024, the way the rules count it', () {
    expect(NestBytes.format(1024), '1.0 kB');
    expect(NestBytes.format(1536), '1.5 kB');
  });

  test('past a hundred the decimal stops earning its place', () {
    expect(NestBytes.format(1024 * 150), '150 kB');
  });

  test('megabytes are where a household"s documents actually live', () {
    expect(NestBytes.format(1024 * 1024), '1.0 MB');
    expect(NestBytes.format((2.5 * 1024 * 1024).round()), '2.5 MB');
  });

  test('the cap reads as the number the rules refuse past', () {
    expect(NestBytes.format(20 * 1024 * 1024), '20.0 MB');
  });

  test('it never runs off the end of the units it has', () {
    // A gigabyte cannot get past `storage.rules`, but the formatter must not
    // index past the last unit if one ever does.
    expect(NestBytes.format(5 * 1024 * 1024 * 1024), endsWith('MB'));
  });
}
