import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../features/documents/data/document_directory.dart';
import '../features/household/model/household_view.dart';
import '../features/photo_frames/data/frame_photo_picker.dart';
import '../features/photo_frames/data/frame_photo_store.dart';
import '../features/photo_frames/data/photo_frame_repository.dart';
import '../features/photo_frames/state/frame_photos_controller.dart';
import '../features/photo_frames/state/photo_frames_controller.dart';
import '../features/photo_frames/ui/frame_photos_screen.dart';
import '../features/photo_frames/ui/photo_frames_screen.dart';
import 'household_route.dart';
import 'photo_frame_route.dart';

ShellRoute photoFrameRoute() => ShellRoute(
  builder: (context, state, child) {
    final householdId = HouseholdRoute.idFrom(state);
    final view = context.read<HouseholdView>();
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => PhotoFramesController(
            photoFrameRepository: context.read<PhotoFrameRepository>(),
            householdId: householdId,
            members: view.members,
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => FramePhotosController(
            photoStore: context.read<FramePhotoStore>(),
            photoPicker: context.read<FramePhotoPicker>(),
            documentDirectory: context.read<DocumentDirectory>(),
            householdId: householdId,
            uploaderUid: view.viewerUid,
          ),
        ),
      ],
      child: child,
    );
  },
  routes: [
    GoRoute(
      path: PhotoFrameRoute.path,
      builder: (context, state) => const PhotoFramesScreen(),
    ),
    GoRoute(
      path: PhotoFrameRoute.photosPath,
      builder: (context, state) => const FramePhotosScreen(),
    ),
  ],
);
