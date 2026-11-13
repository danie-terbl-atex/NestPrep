import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../features/avatars/data/avatar_photo_picker.dart';
import '../features/avatars/data/avatar_photo_store.dart';
import '../features/avatars/data/avatar_repository.dart';
import '../features/avatars/data/avatar_seen_stage_store.dart';
import '../features/avatars/data/firestore_avatar_repository.dart';
import '../features/avatars/data/image_picker_avatar_photo_picker.dart';
import '../features/avatars/data/secure_storage_avatar_seen_stage_store.dart';
import '../features/avatars/data/storage_avatar_photo_store.dart';

List<SingleChildWidget> avatarProviders() => [
  Provider<AvatarRepository>(
    create: (context) =>
        FirestoreAvatarRepository(context.read<FirebaseFirestore>()),
  ),
  Provider<AvatarPhotoStore>(
    create: (context) =>
        StorageAvatarPhotoStore(context.read<FirebaseStorage>()),
  ),
  Provider<AvatarPhotoPicker>(create: (_) => ImagePickerAvatarPhotoPicker()),
  Provider<AvatarSeenStageStore>(
    create: (_) => SecureStorageAvatarSeenStageStore(),
  ),
];
