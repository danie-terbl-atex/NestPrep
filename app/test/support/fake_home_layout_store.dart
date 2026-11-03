import 'package:nestprep/features/today/data/home_layout_store.dart';
import 'package:nestprep/features/today/model/home_layout.dart';

final class FakeHomeLayoutStore implements HomeLayoutStore {
  FakeHomeLayoutStore([this.kept]);

  HomeLayout? kept;

  @override
  Future<HomeLayout?> read() async => kept;

  @override
  Future<void> write(HomeLayout layout) async => kept = layout;
}
