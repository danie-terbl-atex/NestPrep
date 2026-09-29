import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import '../../../shared/failure/app_failure.dart';

/// AES-256-GCM for the phone's offline copies (documents ADR-0007): a fresh
/// 96-bit nonce per file, laid out as `nonce ‖ ciphertext ‖ tag`. A file
/// whose tag does not check out — changed on disk, or sealed under another
/// key — is refused as `offlineCopyUnreadable`, never shown.
///
/// Sealing and opening run in a background isolate: a 20 MiB PDF is seconds
/// of work, and the screen does not stop for it.
abstract final class OfflineCopyCipher {
  static const keyLength = 32;

  /// 32 bytes from the platform's secure random source.
  static Uint8List newKey() {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(keyLength, (_) => random.nextInt(256)),
    );
  }

  static Future<Uint8List> seal(List<int> key, List<int> clear) =>
      Isolate.run(() => _seal(key, clear));

  static Future<Uint8List> open(List<int> key, List<int> sealed) async {
    try {
      return await Isolate.run(() => _open(key, sealed));
    } on SecretBoxAuthenticationError {
      throw const DocumentFailure(DocumentProblem.offlineCopyUnreadable);
    } on ArgumentError {
      // Too short to hold a nonce and a tag: not a file this sealed.
      throw const DocumentFailure(DocumentProblem.offlineCopyUnreadable);
    }
  }

  static Future<Uint8List> _seal(List<int> key, List<int> clear) async {
    final algorithm = AesGcm.with256bits();
    final box = await algorithm.encrypt(clear, secretKey: SecretKey(key));
    return box.concatenation();
  }

  static Future<Uint8List> _open(List<int> key, List<int> sealed) async {
    final algorithm = AesGcm.with256bits();
    final box = SecretBox.fromConcatenation(
      sealed,
      nonceLength: algorithm.nonceLength,
      macLength: algorithm.macAlgorithm.macLength,
    );
    final clear = await algorithm.decrypt(box, secretKey: SecretKey(key));
    return Uint8List.fromList(clear);
  }
}
