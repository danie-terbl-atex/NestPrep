/// Who an emergency contact is to the household, which decides where they sit
/// on the sheet — parents first, the hospital last (nanny-hub ADR-0003). The
/// names are stored, and `nanny_hub.rules` spells them the same way.
enum ContactKind {
  parent,
  backup,
  doctor,
  hospital,
  other,
}
