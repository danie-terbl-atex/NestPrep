import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../features/appearance/data/appearance_store.dart';
import '../features/appearance/data/secure_storage_appearance_store.dart';
import '../features/appearance/state/appearance_controller.dart';

List<SingleChildWidget> appearanceProviders() => [
  Provider<AppearanceStore>(
    create: (context) => SecureStorageAppearanceStore(),
  ),
  ChangeNotifierProvider<AppearanceController>(
    create: (context) =>
        AppearanceController(store: context.read<AppearanceStore>()),
  ),
];
