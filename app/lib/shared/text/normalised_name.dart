/// How a free-text name typed by one person is compared with one typed by
/// another. "Milk", "milk " and "MILK" are one thing to a household, so they are
/// one thing to the history that groceries ranks its chips from and to the meal
/// library that meal planning deduplicates (groceries ADR-0001,
/// meal-planning ADR-0001).
///
/// It is deliberately not a *display* transform: what somebody typed is what
/// they see (`FE-10`). This is only the key.
String normalisedName(String name) =>
    name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
