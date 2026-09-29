import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../features/home_care/data/cleaning_job_repository.dart';
import '../features/home_care/data/firebase_translation_repository.dart';
import '../features/home_care/data/firestore_cleaning_job_repository.dart';
import '../features/home_care/data/firestore_helper_profile_repository.dart';
import '../features/home_care/data/firestore_home_care_library_repository.dart';
import '../features/home_care/data/firestore_routine_repository.dart';
import '../features/home_care/data/flutter_tts_read_aloud.dart';
import '../features/home_care/data/helper_profile_repository.dart';
import '../features/home_care/data/home_care_library_repository.dart';
import '../features/home_care/data/image_picker_photo_source.dart';
import '../features/home_care/data/job_photo_store.dart';
import '../features/home_care/data/read_aloud.dart';
import '../features/home_care/data/routine_repository.dart';
import '../features/home_care/data/storage_job_photo_store.dart';
import '../features/home_care/data/translation_repository.dart';
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
  // V2: room routines, the helper's language and read-aloud (home-care
  // ADR-0004, ADR-0006).
  Provider<RoutineRepository>(
    create: (context) =>
        FirestoreRoutineRepository(context.read<FirebaseFirestore>()),
  ),
  Provider<HelperProfileRepository>(
    create: (context) =>
        FirestoreHelperProfileRepository(context.read<FirebaseFirestore>()),
  ),
  Provider<TranslationRepository>(
    create: (context) => FirebaseTranslationRepository(
      context.read<FirebaseFirestore>(),
      context.read<FirebaseFunctions>(),
    ),
  ),
  Provider<ReadAloud>(create: (context) => FlutterTtsReadAloud()),
];
