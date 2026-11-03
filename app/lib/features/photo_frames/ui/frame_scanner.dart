import 'package:flutter/widgets.dart';

abstract interface class FrameScanner {
  Widget build({required ValueChanged<String> onScanned});
}
