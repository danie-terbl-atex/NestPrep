import 'package:cloud_functions/cloud_functions.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../features/mental_load/data/card_image_sharer.dart';
import '../features/mental_load/data/platform_card_image_sharer.dart';
import '../features/school_letter/data/callable_school_letter_reader.dart';
import '../features/school_letter/data/device_letter_picker.dart';
import '../features/school_letter/data/letter_picker.dart';
import '../features/school_letter/data/school_letter_reader.dart';

/// Calendar V2's collaborators, each behind its interface so a widget test
/// substitutes a fake (foundation ADR-0006): the letter reader (a callable),
/// the letter picker (camera, photos, files) and the card sharer.
List<SingleChildWidget> calendarV2Providers() => [
  Provider<SchoolLetterReader>(
    create: (context) =>
        CallableSchoolLetterReader(context.read<FirebaseFunctions>()),
  ),
  Provider<LetterPicker>(create: (context) => DeviceLetterPicker()),
  Provider<CardImageSharer>(create: (context) => PlatformCardImageSharer()),
];
