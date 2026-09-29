import 'dart:typed_data';

/// A finished data export (accounts ADR-0006): where the server wrote it, how
/// long it can be fetched, and the bytes once the app has them.
final class AccountExport {
  const AccountExport({
    required this.path,
    required this.expiresAt,
    required this.fileCount,
  });

  /// Its place in Storage, readable by this account alone.
  final String path;

  /// When the Storage rule stops serving it — an hour after it was written.
  final DateTime expiresAt;

  /// Vault files listed in it; their bytes stay in the vault.
  final int fileCount;

  String get fileName => 'nestprep-my-data.json';
}

/// The export with its bytes, ready to hand to the share sheet.
final class DownloadedExport {
  const DownloadedExport({required this.export, required this.bytes});

  final AccountExport export;
  final Uint8List bytes;
}
