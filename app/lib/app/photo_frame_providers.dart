import 'package:app_links/app_links.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../features/add_to_woolworths/data/woolworths_store_finder.dart';
import '../features/add_to_woolworths/data/woolworths_web_client.dart';
import '../features/photo_frames/data/callable_photo_frame_directory.dart';
import '../features/photo_frames/data/firestore_photo_frame_repository.dart';
import '../features/photo_frames/data/frame_photo_picker.dart';
import '../features/photo_frames/data/frame_photo_store.dart';
import '../features/photo_frames/data/image_picker_frame_photo_picker.dart';
import '../features/photo_frames/data/photo_frame_directory.dart';
import '../features/photo_frames/data/photo_frame_repository.dart';
import '../features/photo_frames/data/storage_frame_photo_store.dart';
import '../features/photo_frames/state/pending_share.dart';
import '../features/photo_frames/ui/camera_frame_scanner.dart';
import '../features/photo_frames/ui/frame_scanner.dart';

List<SingleChildWidget> photoFrameProviders() => [
  Provider<PhotoFrameRepository>(
    create: (context) =>
        FirestorePhotoFrameRepository(context.read<FirebaseFirestore>()),
  ),
  Provider<PhotoFrameDirectory>(
    create: (context) =>
        CallablePhotoFrameDirectory(context.read<FirebaseFunctions>()),
  ),
  Provider<FrameScanner>(create: (_) => const CameraFrameScanner()),
  Provider<FramePhotoStore>(
    create: (context) =>
        StorageFramePhotoStore(context.read<FirebaseStorage>()),
  ),
  Provider<FramePhotoPicker>(create: (_) => ImagePickerFramePhotoPicker()),
  Provider<WoolworthsStoreFinder>(
    create: (_) => WoolworthsStoreFinder(WoolworthsWebClient()),
  ),
  // Not lazy: the link stream is broadcast and never replays a cold-start link.
  ChangeNotifierProvider<PendingShare>(
    lazy: false,
    create: (_) => PendingShare(links: AppLinks().uriLinkStream),
  ),
];
