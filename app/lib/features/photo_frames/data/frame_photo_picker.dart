import 'dart:typed_data';

typedef PickedPhoto = Future<Uint8List> Function();

abstract interface class FramePhotoPicker {
  Future<List<PickedPhoto>> pickMany({required int limit});
}
