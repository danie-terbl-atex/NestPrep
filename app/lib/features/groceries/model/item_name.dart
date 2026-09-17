/// How a free-text item name is compared with another. "Milk", "milk " and
/// "MILK" are one thing to a person, so they are one thing to the history the
/// quick re-add chips are built from (groceries ADR-0001).
///
/// It is deliberately not a *display* transform: what somebody typed is what
/// they see (`FE-10`). This is only the key.
String normalisedItemName(String name) =>
    name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
