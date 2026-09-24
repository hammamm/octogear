import 'package:decimal/decimal.dart';

/// `Double` helpers ported from the iOS codebase's `Double` extension.
///
/// Members present in the Swift source but intentionally not ported here:
///  * `toString` - Dart's `double` already has a `toString()` (and, for this
///    extension's exact "%.2f" behavior, `toStringAsFixed(2)`). An extension
///    can't override an existing instance member - `x.toString()` would
///    keep calling `Object.toString()` regardless, so redeclaring it here
///    would be dead code. Use `toStringAsFixed(2)` directly, or [clean]
///    below if you want the "%.2f" logic combined with the whole-number
///    shortcut.
extension DoubleExtension on double {
  /// "%.0f" when this is a whole number, otherwise "%.2f".
  ///
  /// e.g. `5.0.clean == '5'`, `5.5.clean == '5.50'`.
  String get clean => this % 1 == 0 ? toStringAsFixed(0) : toStringAsFixed(2);

  /// This value as an arbitrary-precision [Decimal], rounded to 2 decimal
  /// places (rounding half away from zero, e.g. 1.005 -> 1.01).
  ///
  /// Mirrors Swift's `getDecimal`, which rounded an `NSDecimalNumber` to
  /// scale 2 with `.plain` rounding (round-half-up); `Decimal.round` uses
  /// the same half-up rule. Goes through `toString()` rather than
  /// `Decimal`'s binary-double constructors, since `double` itself is
  /// already an imprecise binary representation - parsing its shortest
  /// round-trippable string is the closest a `Decimal` conversion can get
  /// to "what this double looks like written down".
  Decimal get roundedDecimal => Decimal.parse(toString()).round(scale: 2);
}
