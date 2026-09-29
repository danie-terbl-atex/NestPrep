/// What came back: the link, shown once, and when it ends.
class SharedLink {
  const SharedLink({
    required this.shareId,
    required this.url,
    required this.expiresAt,
  });

  final String shareId;
  final Uri url;
  final DateTime expiresAt;
}
