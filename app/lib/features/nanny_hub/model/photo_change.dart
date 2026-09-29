import 'dart:typed_data';

/// What an editing sheet did to a record's photo: nothing, a new one picked,
/// or the old one taken away. The sheet only says; storing and removing is the
/// controller's (`FE-05`).
sealed class PhotoChange {
  const PhotoChange();
}

final class PhotoKept extends PhotoChange {
  const PhotoKept();
}

final class PhotoPicked extends PhotoChange {
  const PhotoPicked(this.bytes);

  /// As the phone gave them; compressed on the way out.
  final Uint8List bytes;
}

final class PhotoRemoved extends PhotoChange {
  const PhotoRemoved();
}
