import 'chore_picture_catalogue.dart';

enum ChorePictureCategory {
  morning,
  hygiene,
  bedroom,
  kitchen,
  meals,
  laundry,
  cleaning,
  outdoor,
  pets,
  school,
  bedtime,
  helping,
  activities,
  kindness,
}

/// One sticker in the bundled library a task can wear (todos ADR-0005).
class ChorePicture {
  const ChorePicture({
    required this.id,
    required this.label,
    required this.category,
    required this.keywords,
  });

  final String id;
  final String label;
  final ChorePictureCategory category;
  final List<String> keywords;

  String get asset => 'assets/chore_pictures/$id.webp';

  /// The picture stored as [id], or null for none and for an id this build
  /// does not ship: a newer build's picture draws nothing here, never an error.
  static ChorePicture? byId(String? id) => id == null ? null : _byId[id];

  static final Map<String, ChorePicture> _byId = {
    for (final picture in chorePictureCatalogue) picture.id: picture,
  };
}
