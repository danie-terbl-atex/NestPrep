import 'dart:ui';

/// The three shapes a lunch card is exported in (lunch-box ADR-0005). Each is
/// laid out 360 points wide — a phone's width, so the kit's type sizes read
/// the way they do in the app — and exported at [pixelRatio], 1080 pixels
/// wide, which is what Instagram and WhatsApp keep.
enum LunchCardFormat {
  /// 9:16, an Instagram or TikTok story — 1080 × 1920.
  story(Size(360, 640)),

  /// 1:1, a square post — 1080 × 1080.
  post(Size(360, 360)),

  /// 4:5, large in a WhatsApp chat and an Instagram portrait post —
  /// 1080 × 1350.
  chat(Size(360, 450));

  const LunchCardFormat(this.logicalSize);

  /// The layout's size in logical points.
  final Size logicalSize;

  static const pixelRatio = 3.0;

  /// The exported image's size in pixels.
  Size get exportSize => logicalSize * pixelRatio;

  /// A story's top and bottom are covered by the app's own bars — the
  /// account name above, the reply field below — so the card keeps its
  /// words out of them.
  bool get hasSafeZones => this == story;

  /// The square has room for one line of each day's food, the taller two
  /// for more.
  bool get isCompact => this == post;
}
