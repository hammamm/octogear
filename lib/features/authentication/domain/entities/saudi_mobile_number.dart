/// A validated Saudi national mobile number.
///
/// The backend accepts several representations, but the app keeps one clear
/// value: nine digits beginning with `5`. It is intentionally not persisted.
class SaudiMobileNumber {
  const SaudiMobileNumber._(this.nationalNumber);

  static final _validNationalNumber = RegExp(r'^5\d{8}$');

  final String nationalNumber;

  String get displayValue => '+966 $nationalNumber';

  /// Normalizes the common `+966`, `966`, `05`, and `5` forms before applying
  /// the product's current nine-digit Saudi mobile rule.
  static SaudiMobileNumber? tryParse(String input) {
    var digits = input.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('966')) digits = digits.substring(3);
    if (digits.startsWith('0')) digits = digits.substring(1);

    return _validNationalNumber.hasMatch(digits)
        ? SaudiMobileNumber._(digits)
        : null;
  }
}
