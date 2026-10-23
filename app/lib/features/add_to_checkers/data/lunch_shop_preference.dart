import 'retailer_preference.dart';

/// The shop *Plan my week* plans at, kept on this phone per household
/// (lunch-box ADR-0026) — a separate choice from the grocery screen's *Shop
/// at*, which stays Checkers-only (add-to-pnp ADR-0001 §1).
abstract interface class LunchShopPreference implements RetailerPreference {}
