import 'package:nestprep/features/appearance/data/appearance_store.dart';
import 'package:nestprep/features/appearance/model/appearance.dart';

final class FakeAppearanceStore implements AppearanceStore {
  FakeAppearanceStore([this.kept]);

  Appearance? kept;
  var writes = 0;

  @override
  Future<Appearance?> read() async => kept;

  @override
  Future<void> write(Appearance appearance) async {
    writes++;
    kept = appearance;
  }
}
