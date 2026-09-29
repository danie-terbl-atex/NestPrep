/// How a child is named on a shared card (lunch-box ADR-0005). A first name
/// is opted into on every share and never remembered.
enum LunchCardNaming {
  /// Nothing at all: a one-child card says only "Lunches this week", and a
  /// family card numbers its columns.
  none,

  /// The initials the app's avatars already show. The default.
  initials,

  /// The first word of the child's name — never a surname.
  firstNames,
}
