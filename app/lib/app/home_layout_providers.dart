import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../features/today/data/home_layout_store.dart';
import '../features/today/data/secure_storage_home_layout_store.dart';
import '../features/today/state/home_layout_controller.dart';
import 'home_layout_access.dart';

List<SingleChildWidget> homeLayoutProviders() => [
  Provider<HomeLayoutStore>(
    create: (context) => SecureStorageHomeLayoutStore(),
  ),
  ChangeNotifierProvider<HomeLayoutController>(
    create: (context) => HomeLayoutController(
      store: context.read<HomeLayoutStore>(),
      canSwitch: HomeLayoutAccess.isAvailable,
    ),
  ),
];
