import '../model/push_arrival.dart';
import '../model/push_token.dart';

/// One Android notification channel: what the phone's own settings call it,
/// and how loudly it may speak.
final class PushChannelSpec {
  const PushChannelSpec({
    required this.id,
    required this.name,
    required this.description,
    this.isImportant = false,
  });

  final String id;
  final String name;
  final String description;

  /// Heads-up and sound, rather than a quiet line in the shade.
  final bool isImportant;
}

/// The one door to the phone's push service (notifications ADR-0001) —
/// behind an interface so a widget test drives it with a fake and never pumps
/// the messaging SDK (foundation ADR-0006).
abstract interface class PushGateway {
  /// The kind of phone this is, or null where pushes do not exist here.
  PushPlatform? get platform;

  /// What the phone says now, without asking anybody anything.
  Future<PushPermission> permission();

  /// Shows the phone's own prompt — only ever from a person's tap
  /// (notifications ADR-0003).
  Future<PushPermission> requestPermission();

  /// This phone's token, or null when it has none to give — an iPhone with no
  /// APNs key behind the project yet, a phone with no Play services.
  Future<String?> token();

  /// A new token for this phone, whenever the service rotates it.
  Stream<String> get tokenRefreshes;

  /// A push that arrived while the app was open.
  Stream<PushArrival> get foregroundArrivals;

  /// A push somebody tapped while the app was in the background.
  Stream<PushArrival> get openedArrivals;

  /// The push somebody tapped to start the app, if they did.
  Future<PushArrival?> launchArrival();

  /// Forgets this phone's token, so the server's next send finds it dead —
  /// what signing out does.
  Future<void> forgetToken();

  /// Creates the Android channels; nothing on iOS.
  Future<void> prepareChannels(List<PushChannelSpec> channels);
}
