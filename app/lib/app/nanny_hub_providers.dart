import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../features/nanny_hub/data/callable_shift_directory.dart';
import '../features/nanny_hub/data/firestore_nanny_hub_repository.dart';
import '../features/nanny_hub/data/firestore_shift_repository.dart';
import '../features/nanny_hub/data/image_picker_photo_picker.dart';
import '../features/nanny_hub/data/nanny_hub_repository.dart';
import '../features/nanny_hub/data/photo_picker.dart';
import '../features/nanny_hub/data/photo_store.dart';
import '../features/nanny_hub/data/shift_directory.dart';
import '../features/nanny_hub/data/shift_repository.dart';
import '../features/nanny_hub/data/storage_photo_store.dart';

/// The nanny hub's repositories, each behind its interface so a widget test
/// substitutes a fake (foundation ADR-0006). In their own file so the
/// provider graph gains one line (nanny-hub ADR-0003).
List<SingleChildWidget> nannyHubProviders() => [
  Provider<NannyHubRepository>(
    create: (context) =>
        FirestoreNannyHubRepository(context.read<FirebaseFirestore>()),
  ),
  Provider<ShiftRepository>(
    create: (context) =>
        FirestoreShiftRepository(context.read<FirebaseFirestore>()),
  ),
  Provider<ShiftDirectory>(
    create: (context) =>
        CallableShiftDirectory(context.read<FirebaseFunctions>()),
  ),
  Provider<PhotoStore>(
    create: (context) => StoragePhotoStore(context.read<FirebaseStorage>()),
  ),
  Provider<PhotoPicker>(create: (context) => ImagePickerPhotoPicker()),
];
