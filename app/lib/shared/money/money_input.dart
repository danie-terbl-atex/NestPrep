import 'money.dart';

/// Reads an amount somebody typed into whole cents, or null when it is not
/// one (`ENG-09`, `FE-10`): `12`, `12.5`, `12.50`, `R12,50` and `R 1 250`
/// all read; `12.505`, `abc` and a minus sign do not. Nothing is rounded —
/// a third decimal is refused rather than quietly dropped.
abstract final class MoneyInput {
  static final _pattern = RegExp(r'^(\d{1,7})(?:[.,](\d{1,2}))?$');

  static Money? parse(String text, {Currency currency = Currency.zar}) {
    final cleaned = text
        .trim()
        .replaceFirst(RegExp('^${RegExp.escape(currency.symbol)}'), '')
        .replaceAll(RegExp(r'\s'), '');
    final match = _pattern.firstMatch(cleaned);
    if (match == null) return null;
    final whole = int.parse(match.group(1)!);
    final fraction = (match.group(2) ?? '').padRight(2, '0');
    return Money(whole * 100 + int.parse(fraction), currency: currency);
  }

  /// What goes back in a field to edit it: `12.50`, with no symbol.
  static String edit(Money money) {
    final whole = money.cents ~/ 100;
    final part = (money.cents % 100).toString().padLeft(2, '0');
    return '$whole.$part';
  }
}
