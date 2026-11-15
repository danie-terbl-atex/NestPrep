import '../model/appearance.dart';

abstract interface class AppearanceStore {
  Future<Appearance?> read();

  Future<void> write(Appearance appearance);
}
