/// What Pick n Pay's product detail says is in a product (add-to-pnp
/// ADR-0002 §4): its allergens and allergen warnings as one line, and its
/// ingredients. Both null when it says nothing — the contents are unknown.
typedef PnpContents = ({String? allergenText, String? ingredientsText});
