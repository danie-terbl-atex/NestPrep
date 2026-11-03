import '../model/home_layout.dart';

abstract interface class HomeLayoutStore {
  Future<HomeLayout?> read();

  Future<void> write(HomeLayout layout);
}
