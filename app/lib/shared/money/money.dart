import 'package:flutter/foundation.dart';

/// The currencies NestPrep stores. South African rand only, for now
/// (lunch-box ADR-0007); another is an additive change with its own ADR.
enum Currency {
  zar('ZAR', 'R');

  const Currency(this.code, this.symbol);

  /// ISO 4217, as stored.
  final String code;

  /// What a person reads before the amount.
  final String symbol;

  static Currency? fromCode(String code) =>
      values.where((currency) => currency.code == code).firstOrNull;
}

/// An amount of money: whole minor units and the currency they are in
/// (`ENG-20`, `BE-11`). Never a double, never a bare number.
@immutable
final class Money implements Comparable<Money> {
  const Money(this.cents, {this.currency = Currency.zar});

  const Money.zero({this.currency = Currency.zar}) : cents = 0;

  /// Minor units — cents for the rand.
  final int cents;
  final Currency currency;

  bool get isZero => cents == 0;
  bool get isNegative => cents < 0;

  Money operator +(Money other) {
    _sameCurrency(other);
    return Money(cents + other.cents, currency: currency);
  }

  Money operator -(Money other) {
    _sameCurrency(other);
    return Money(cents - other.cents, currency: currency);
  }

  Money abs() => Money(cents.abs(), currency: currency);

  void _sameCurrency(Money other) {
    if (other.currency != currency) {
      throw ArgumentError.value(other, 'other', 'is not in ${currency.code}');
    }
  }

  /// `R12.50`, `R0.00`, `-R3.40` — the one way an amount is written for a
  /// person, rounded nowhere because it is whole cents already.
  String get display {
    final whole = cents.abs() ~/ 100;
    final part = (cents.abs() % 100).toString().padLeft(2, '0');
    final sign = cents < 0 ? '-' : '';
    return '$sign${currency.symbol}${_grouped(whole)}.$part';
  }

  /// Whole rands when the cents are zero — `R250` — for a budget, which is
  /// set in round numbers and read at a glance.
  String get displayShort => cents % 100 == 0 && cents >= 0
      ? '${currency.symbol}${_grouped(cents ~/ 100)}'
      : display;

  static String _grouped(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    for (var index = 0; index < digits.length; index++) {
      if (index > 0 && (digits.length - index) % 3 == 0) buffer.write(' ');
      buffer.write(digits[index]);
    }
    return buffer.toString();
  }

  @override
  int compareTo(Money other) {
    _sameCurrency(other);
    return cents.compareTo(other.cents);
  }

  @override
  bool operator ==(Object other) =>
      other is Money && other.cents == cents && other.currency == currency;

  @override
  int get hashCode => Object.hash(cents, currency);

  @override
  String toString() => '${currency.code} $cents';
}
