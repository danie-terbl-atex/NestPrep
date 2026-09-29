import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../features/nanny_hub/data/booking_repository.dart';
import '../features/nanny_hub/data/cache_warmer.dart';
import '../features/nanny_hub/data/callable_shift_directory.dart';
import '../features/nanny_hub/data/file_offline_shelf.dart';
import '../features/nanny_hub/data/firestore_booking_repository.dart';
import '../features/nanny_hub/data/firestore_cache_warmer.dart';
import '../features/nanny_hub/data/firestore_house_code_repository.dart';
import '../features/nanny_hub/data/firestore_nanny_hub_repository.dart';
import '../features/nanny_hub/data/firestore_photo_update_repository.dart';
import '../features/nanny_hub/data/firestore_pickup_repository.dart';
import '../features/nanny_hub/data/firestore_shift_repository.dart';
import '../features/nanny_hub/data/house_code_repository.dart';
import '../features/nanny_hub/data/image_picker_photo_picker.dart';
import '../features/nanny_hub/data/nanny_hub_repository.dart';
import '../features/nanny_hub/data/offline_shelf.dart';
import '../features/nanny_hub/data/photo_picker.dart';
import '../features/nanny_hub/data/photo_store.dart';
import '../features/nanny_hub/data/photo_update_repository.dart';
import '../features/nanny_hub/data/pickup_repository.dart';
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
  // ---- pickups (nanny-hub ADR-0005) ----
  Provider<PickupRepository>(
    create: (context) =>
        FirestorePickupRepository(context.read<FirebaseFirestore>()),
  ),
  // ---- shift-only access and offline (nanny-hub ADR-0006, ADR-0007) ----
  Provider<BookingRepository>(
    create: (context) =>
        FirestoreBookingRepository(context.read<FirebaseFirestore>()),
  ),
  Provider<HouseCodeRepository>(
    create: (context) =>
        FirestoreHouseCodeRepository(context.read<FirebaseFirestore>()),
  ),
  Provider<CacheWarmer>(
    create: (context) =>
        FirestoreCacheWarmer(context.read<FirebaseFirestore>()),
  ),
  Provider<OfflineShelf>(create: (context) => FileOfflineShelf()),
  // ---- photo updates (nanny-hub ADR-0004) ----
  Provider<PhotoUpdateRepository>(
    create: (context) =>
        FirestorePhotoUpdateRepository(context.read<FirebaseFirestore>()),
  ),
];
