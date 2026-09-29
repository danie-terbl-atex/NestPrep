/// One thing to do, or to keep in mind, while using a product (home-care
/// ADR-0002). The words are in `HomeCareCopy`; which products need which is
/// the catalogue's.
///
/// In the order a helper should read them: what protects her first, then
/// what protects the house and the children.
enum Precaution {
  corrosive,
  flammable,
  onlyWithWater,
  gloves,
  eyeProtection,
  freshAir,
  patchTest,
  keepFromChildren,
  keepFromPets,
}
