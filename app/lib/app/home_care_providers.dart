import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../features/home_care/data/cleaning_job_repository.dart';
import '../features/home_care/data/firestore_cleaning_job_repository.dart';
import '../features/home_care/data/firestore_home_care_library_repository.dart';
import '../features/home_care/data/home_care_library_repository.dart';
import '../features/home_care/data/image_picker_photo_source.dart';
import '../features/home_care/data/job_photo_store.dart';
import '../features/home_care/data/storage_job_photo_store.dart';
import '../features/home_care/model/home_care_photo.dart';
import '../features/home_care/state/photo_intake.dart';

/// Home care's part of the app-wide graph (home-care ADR-0001 to ADR-0003):
/// the jobs, the rooms and products, the photos' bytes, and the camera with
/// the compressor behind it — each behind its interface, so a widget test
/// substitutes a fake and never touches a plugin.
///
/// Its own list, spread into `appProviders`, so the shared file changes by
/// one line.
List<SingleChildWidget> homeCareProviders() => [
  Provider<CleaningJobRepository>(
    create: (context) =>
        FirestoreCleaningJobRepository(context.read<FirebaseFirestore>()),
  ),
  Provider<HomeCareLibraryRepository>(
    create: (context) =>
        FirestoreHomeCareLibraryRepository(context.read<FirebaseFirestore>()),
  ),
  Provider<JobPhotoStore>(
    create: (context) => StorageJobPhotoStore(context.read<FirebaseStorage>()),
  ),
  Provider<PhotoIntake>(
    create: (context) => PhotoIntake(
      source: ImagePickerPhotoSource(),
      compressor: HomeCarePhoto.compressor,
    ),
  ),
];
